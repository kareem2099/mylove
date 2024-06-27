import 'package:bottom_picker/resources/arrays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:bottom_picker/bottom_picker.dart'; // Import bottom_picker
import 'package:mylove/screens/upload_screen.dart';


class AddImageFormPage extends StatefulWidget {
  final XFile imageFile;
  final bool isVideo;

  const AddImageFormPage(
      {super.key, required this.imageFile, this.isVideo = false});

  @override
  State <AddImageFormPage> createState() => _AddImageFormPageState();
}

class _AddImageFormPageState extends State<AddImageFormPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
   DateTime _selectedDate = DateTime.now(); // Define _selectedDate here
   bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _image = widget.imageFile;
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate); // Initialize date field
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
        if(mounted) {
          // Handle errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _uploadImageNow(File imageFile) async {
    if (_image != null) {
      try {
        setState(() {
          _isLoading = true;
        });
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

        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          throw FirebaseAuthException(code: 'No_user', message: 'No USer is currently signed in.');
        }

        // Upload to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref('uploads/images/$userId/${DateTime.now().toString()}');
        await ref.putFile(imageFile);
        final String downloadUrl = await ref.getDownloadURL();

        // Store metadata in Firestore
        await FirebaseFirestore.instance.collection('images').add({
          'userId': userId,
          'ImageTitle': _titleController.text,
          'ImageDate': _dateController.text,
          'ImageDescription': _descriptionController.text,
          'ImageUrl': downloadUrl,
        });
if(mounted) {
  // Dismiss the loading dialog
  Navigator.pop(context);

  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text('Image uploaded successfully!'),
        backgroundColor: Colors.green),
  );
  // Navigate to UploadScreen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const UploadScreen()),
  );
}

        // Optionally, clear the form or navigate away
        _titleController.clear();
        _dateController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });

      } on FirebaseException catch (e) {
        if (mounted) {
          // Dismiss the loading dialog
          Navigator.pop(context);

          // Handle errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error uploading image: ${e.message}'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() {
          _isLoading=false;
        });
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
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            // Date Picker with Button
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadImage,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}
