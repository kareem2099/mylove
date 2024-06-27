import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart'; // Import for phone number input
import 'package:mylove/screens/settings_screen.dart';

class ProfilePage extends StatefulWidget {
  final String name;
  final String userId;
  final String email;
  final String aboutMe;
  final String? photoURL; // Make photoURL optional
  const ProfilePage({super.key, required this.name, required this.userId, required this.email, required this.aboutMe, this.photoURL});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController(); // Controller for phone number
  String? _userId;
  String? _photoURL;
  String? _email; // To store the user's email
  final PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'US'); // For phone number input
  File?_imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        setState(() {
          _nameController.text = docSnapshot.get('fullName') ?? '';
          _aboutMeController.text = docSnapshot.get('aboutMe') ?? '';
          _userId = docSnapshot.get('userId');
          _photoURL = docSnapshot.get('photoURL');
          _email = user.email; // Get the email from the User object
          _phoneNumberController.text = docSnapshot.get('phoneNumber') ?? ''; // Get phone number from Firestore
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
    });
    if (_imageFile != null) {
      _uploadImage();}
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isLoading = true;
    });
    final User? user = _auth.currentUser;
    if (user != null && _imageFile != null) {
      final storageRef = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
      final uploadTask = storageRef.putFile(_imageFile!);
      await uploadTask.whenComplete(() async {
        _photoURL = await storageRef.getDownloadURL();
        await _firestore.collection('users').doc(user.uid).update({
          'photoURL': _photoURL,
        });
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  // Helper function to get the appropriate ImageProvider
  ImageProvider<Object>? _getImageProvider() {
    if (_photoURL != null) {
      return NetworkImage(_photoURL!);
    } else if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else {
      return const AssetImage('assets/images/first.jpg'); // Your default image path
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': _nameController.text,
        'aboutMe': _aboutMeController.text,
        'phoneNumber': _phoneNumber.phoneNumber,
      });
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.pink[300],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[100]!, Colors.pink[300]!],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // User Avatar with a heart-shaped border
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent,
                        width: 3.0,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage: _getImageProvider(),
                        child: _photoURL == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Information (Read-only)
              GestureDetector(
                onTap: () {Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      onProfileUpdated: () {
                        _fetchUserData();
                        setState(() {});
                      },
                    ),
                  ),
                );
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Name with settings icon
                      Row(
                        children: [
                          Text(
                            'Full Name: ${widget.name}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.settings, color: Colors.white, size: 16),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Email Address with settings icon
                      if (widget.email.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              'Email: ${widget.email}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.settings, color: Colors.white, size: 16),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // Phone Number with settings icon
                      Row(
                        children: [
                          Text(
                            'Phone Number: ${_phoneNumber.phoneNumber ?? "Not set"}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.settings, color: Colors.white, size: 16),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // User ID with settings icon
                      if (_userId != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'User ID: $_userId',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),

                          ],
                        ),
                      const SizedBox(height: 8),

                      // About Me with scrolling and settings icon
                      const Row(
                        children: [
                          Text(
                            'About Me: ',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.settings, color: Colors.white, size: 16),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        child: Expanded(
                          child: Text(
                            _aboutMeController.text,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Make Changes Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        onProfileUpdated: () {
                          _fetchUserData();
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: const Text('Make Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
