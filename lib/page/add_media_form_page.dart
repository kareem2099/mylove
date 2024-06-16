import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class AddMediaFormPage extends StatefulWidget {
  final XFile mediaFile;
  final bool isVideo;

  const AddMediaFormPage(
      {Key? key, required this.mediaFile, this.isVideo = false})
      : super(key: key);

  @override
  State <AddMediaFormPage> createState() => _AddMediaFormPageState();
}

class _AddMediaFormPageState extends State<AddMediaFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _mediaFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _mediaFile = widget.mediaFile;
  }

  Future<void> _pickMedia() async {
    XFile? mediaFile;
    if (widget.isVideo) {
      mediaFile = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      mediaFile = await _picker.pickImage(source: ImageSource.gallery);
    }
    setState(() {
      _mediaFile = mediaFile;
    });
  }

  Future<void> _uploadMedia() async {
    if (_mediaFile != null) {
      final File mediaFile = File(_mediaFile!.path);
      try {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Form data saved!'), backgroundColor: Colors.green),
        );

        // Wait for the user to fill out the form and press "Upload"
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Upload'),
            content: const Text('Are you ready to upload the media?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _uploadMediaNow(mediaFile); // Initiate the actual upload
                },
                child: const Text('Upload'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  // Optionally handle cancel action
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadMediaNow(File mediaFile) async {
    if (_mediaFile != null) {
      final File mediaFile = File(_mediaFile!.path);
      try {
        // Upload to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('uploads/media/${DateTime.now().toString()}');
        await ref.putFile(mediaFile);
        final String downloadUrl = await ref.getDownloadURL();

        // Store metadata in Firestore
        await FirebaseFirestore.instance.collection('media').add({
          'MediaTitle': _titleController.text,
          'MediaDate': _dateController.text,
          'MediaDescription': _descriptionController.text,
          'MediaUrl': downloadUrl,
          'IsVideo': widget.isVideo,
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Media uploaded successfully!'),
              backgroundColor: Colors.green),
        );
      } on FirebaseException catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error uploading media: ${e.message}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Media Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_mediaFile != null)
              widget.isVideo
                  ? VideoPlayerWidget(
                      mediaUrl: _mediaFile!.path) // Display video
                  : Image.file(File(_mediaFile!.path)), // Display image
            TextButton(
              onPressed: _pickMedia,
              child: Text(widget.isVideo ? 'Pick Video' : 'Pick Image'),
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            ElevatedButton(
              onPressed: _uploadMedia,
              child: const Text('Upload Media'),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder widget for video player
class VideoPlayerWidget extends StatelessWidget {
  final String mediaUrl;

  const VideoPlayerWidget({super.key, required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement video player functionality
    return const SizedBox(
      height: 200, // Example height, adjust as needed
      child: Center(
        child: Text('Video player not implemented'),
      ),
    );
  }
}
