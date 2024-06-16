import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../page/add_media_form_page.dart';
import '../page/add_photo_form_page.dart';
import '../page/media_detail_page.dart';
import '../page/photo_detail_page.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State <UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddImageFormPage(
            imageFile: image,
            isVideo: false,
          ),
        ),
      );
    }
  }

  Future<void> pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMediaFormPage(
            mediaFile: video,
            isVideo: true,
          ),
        ),
      );
    }
  }

  Future<void> uploadAndSaveMetadata(XFile file, String type, String title,
      String date, String description) async {
    final ref =
    FirebaseStorage.instance.ref('uploads/${DateTime.now().toString()}');
    await ref.putFile(File(file.path));
    final String downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('uploads').add({
      'url': downloadUrl,
      'type': type,
      'title': title,
      'date': date,
      'description': description,
    });
 if (mounted) {
   ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(
       content: Text('File uploaded successfully'),
       backgroundColor: Colors.green,
     ),
   );
 }
  }

  Widget getIconBasedOnType(String type) {
    switch (type) {
      case 'image':
        return const Icon(Icons.image);
      case 'video':
        return const Icon(Icons.videocam);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference ref = FirebaseStorage.instance.refFromURL(fileUrl);
      await ref.delete();

      final collection = FirebaseFirestore.instance.collection('uploads');
      final snapshot = await collection.where('url', isEqualTo: fileUrl).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('File deleted successfully'),
      backgroundColor: Colors.green,
    ),
  );
}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete the file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<String>> getFiles() async {
    ListResult result =
    await FirebaseStorage.instance.ref('uploads/images/').listAll();
    List<String> urls = [];
    for (var ref in result.items) {
      String url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  bool isVideo(String url) {
    return url.endsWith('.mp4');
  }

  Widget buildMediaItem(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic>? data = document.data()! as Map<String, dynamic>?;
    String title = data?['MediaTitle'] as String? ?? 'No Title';
    String date = data?['MediaDate'] as String? ?? 'No Date';
    String description = data?['MediaDescription'] as String? ?? 'No Description';
    String url = data?['MediaUrl'] as String? ?? 'no image url';
    bool IsVideo = data?['IsVideo'] as bool? ?? false;

    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text(title),
            subtitle: Text(description),
            trailing: Text(date),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MediaDetailPage(
                    MediaUrl: url,
                    MediaTitle: title,
                    MediaDate: date,
                    MediaDescription: description,
                    isVideo: IsVideo,
                  ),
                ),
              );
            },
          ),
          if (IsVideo)
            Hero(
              tag: url,
              child: Image.network(url),
            )
          else
            Hero(
              tag: url,
              child: const Icon(Icons.play_arrow),
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              deleteFile(url);
            },
          ),
        ],
      ),
    );
  }

  Widget buildImageItem(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
    String title = data?['ImageTitle'] as String? ?? 'No Title';
    String date = data?['ImageDate'] as String? ?? 'No Date';
    String description = data?['ImageDescription'] as String? ?? 'No Description';
    String imageUrl = data?['ImageUrl'] as String? ?? 'no image url';

    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text(title),
            subtitle: Text(description),
            trailing: Text(date),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PhotoDetailPage(
                    ImageUrl: imageUrl,
                    ImageTitle: title,
                    ImageDate: date,
                    ImageDescription: description,
                  ),
                ),
              );
            },
          ),
          Hero(
            tag: imageUrl,
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload to Firebase Storage'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.image)),
              Tab(icon: Icon(Icons.video_library)),
              Tab(icon: Icon(Icons.image)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // First tab content
            StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collection('images/').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else {
                  return ListView(
                    children:
                    snapshot.data!.docs.map((DocumentSnapshot document) {
                      return buildImageItem(context, document);
                    }).toList(),
                  );
                }
              },
            ),

            // Second tab content
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('media').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const CircularProgressIndicator();
                } else {
                  return ListView(
                    children:
                    snapshot.data!.docs.map((DocumentSnapshot document) {
                      return buildMediaItem(context, document);
                    }).toList(),
                  );
                }
              },
            ),

            // Third tab content
            FutureBuilder<List<String>>(
              future: getFiles(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load images'));
                } else {
                  return AnimationLimiter(
                    child: GridView.count(
                      crossAxisCount: 2,
                      children:
                      List.generate(snapshot.data!.length, (int index) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 2,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: GestureDetector(
                                onTap: () {
                                  if (isVideo(snapshot.data![index])) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MediaDetailPage(
                                          MediaUrl: snapshot.data![index],
                                          MediaTitle: _titleController.text,
                                          MediaDate: _dateController.text,
                                          MediaDescription: _descriptionController.text,
                                          isVideo: true,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PhotoDetailPage(
                                          ImageUrl: snapshot.data![index],
                                          ImageTitle: _titleController.text,
                                          ImageDate: _dateController.text,
                                          ImageDescription: _descriptionController.text,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Hero(
                                  tag: snapshot.data![index],
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.network(
                                        snapshot.data![index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return isVideo(snapshot.data![index])
                                              ? const Icon(
                                            Icons.play_circle_outline,
                                            size: 50,
                                            color: Colors.white,
                                          )
                                              : const Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                              Text(
                                                'A moment lost in time, but our love remains.',
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      if (isVideo(snapshot.data![index]))
                                        Icon(
                                          Icons.play_circle_outline,
                                          size: 50,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'image',
              onPressed: pickImage,
              tooltip: 'Upload Image',
              child: const Icon(Icons.image),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'video',
              onPressed: pickVideo,
              tooltip: 'Upload Video',
              child: const Icon(Icons.video_call),
            ),
          ],
        ),
      ),
    );
  }
}
