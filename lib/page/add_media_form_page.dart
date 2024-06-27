import 'package:bottom_picker/resources/arrays.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:bottom_picker/bottom_picker.dart'; // Import bottom_picker
import 'package:mylove/screens/upload_screen.dart';
import 'package:video_player/video_player.dart';


class AddMediaFormPage extends StatefulWidget {
  final XFile mediaFile;
  final bool isVideo;

  const AddMediaFormPage(
      {super.key, required this.mediaFile, this.isVideo = false});

  @override
  State <AddMediaFormPage> createState() => _AddMediaFormPageState();
}

class _AddMediaFormPageState extends State<AddMediaFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _mediaFile;
  final ImagePicker _picker = ImagePicker();
  DateTime _selectedDate = DateTime.now(); // Define _selectedDate here
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _mediaFile = widget.mediaFile;
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate); // Initialize date field

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
      setState(() {
        _isLoading = true;
      });
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Handle errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _uploadMediaNow(File mediaFile) async {
    if (_mediaFile != null) {
      try {
        // Show a loading dialog
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button to dismiss
          builder: (BuildContext context) {
            return const AlertDialog(
              content: SizedBox(
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          },
        );
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
if (mounted) {
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text('Media uploaded successfully!'),
        backgroundColor: Colors.green),
  );
  // Navigate to UploadScreen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const UploadScreen()),
  );
}
      } on FirebaseException catch (e) {
        // Handle errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error uploading media: ${e.message}'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _openDatePicker() {
    BottomPicker.date(
      pickerTitle: const Text(
        'Set date',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.blue,
        ),
      ),
      dateOrder: DatePickerDateOrder.dmy,
      initialDateTime: DateTime(2021, 12, 23),
      maxDateTime: DateTime(2030),
      minDateTime: DateTime(1998),
      pickerTextStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      // Use onSubmit to update_selectedDate and the text field
      onSubmit: (selectedDate) {
        setState(() {
          _selectedDate = selectedDate;
          _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
        });
      },
      bottomPickerTheme: BottomPickerTheme.plumPlate,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Media Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_mediaFile != null)
                widget.isVideo
                    ? VideoPlayerWidget(
                        mediaUrl: _mediaFile!.path) // Display video
                    : Image.file(File(_mediaFile!.path)), // Display image
              ElevatedButton(
                onPressed: _pickMedia,
                child: Text(widget.isVideo ? 'Pick Video' : 'Pick Image'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _openDatePicker,
                child: Text(
                  'Select Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _uploadMedia,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Upload Media'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class VideoPlayerWidget extends StatefulWidget {
  final String mediaUrl;

  const VideoPlayerWidget({super.key, required this.mediaUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.mediaUrl))
      ..initialize().then((_) {
        setState(() {}); // Update state once initialization is complete
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : const Center(child: CircularProgressIndicator());
  }
}