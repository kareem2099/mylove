import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class AddImageFormPage extends StatefulWidget {
  final XFile imageFile;
  final bool isVideo;

  const AddImageFormPage(
      {Key? key, required this.imageFile, this.isVideo = false})
      : super(key: key);

  @override
  State <AddImageFormPage> createState() => _AddImageFormPageState();
}

class _AddImageFormPageState extends State<AddImageFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _image = widget.imageFile;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  bool _validateForm() {
    if (_titleController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('cutie h3dk emly el form '),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _uploadImage() async {
    if (_image != null && _validateForm()) {
      final File imageFile = File(_image!.path);
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
            content: const Text('Are you ready to upload the image?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  _uploadImageNow(imageFile); // Initiate the actual upload
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

  Future<void> _uploadImageNow(File imageFile) async {
    if (_image != null) {
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
            .ref('uploads/images/${DateTime.now().toString()}');
        await ref.putFile(imageFile);
        final String downloadUrl = await ref.getDownloadURL();

        // Store metadata in Firestore
        await FirebaseFirestore.instance.collection('images').add({
          'ImageTitle': _titleController.text,
          'ImageDate': _dateController.text,
          'ImageDescription': _descriptionController.text,
          'ImageUrl': downloadUrl,
        });

        // Dismiss the loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green),
        );

        // Optionally, clear the form or navigate away
        _titleController.clear();
        _dateController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });

      } on FirebaseException catch (e) {
        // Dismiss the loading dialog
        Navigator.pop(context);

        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error uploading image: ${e.message}'),
              backgroundColor: Colors.red),
        );
      }
    } else {
      // No image was selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No image selected'),
            backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Image Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_image != null)
              Image.file(File(_image!.path))
            else
              TextButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
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
              onPressed: _uploadImage,
              child: const Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}
