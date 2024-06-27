import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:mylove/service/AudioPlayerService.dart';
import 'package:provider/provider.dart';


class SettingsScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated;
  const SettingsScreen({super.key, required this.onProfileUpdated});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _imageFile;
  late Stream<DocumentSnapshot> _userStream;
  bool _isPhoneNumberVerified = false; // Track verification status

  User? get user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
    _userStream = _firestore.collection('users').doc(user!.uid).snapshots();

    // Check if phone number is already verified
    _isPhoneNumberVerified = user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  Future<void> _updateProfile() async {
    if (user == null) return;

    // Show loading dialog
    _showLoadingDialog('Hold tight, love! We are making you even more fabulous...');

    try {
      // Check if the username is unique
      if (_nameController.text.isNotEmpty) {
        bool isUnique = await _isUsernameUnique(_nameController.text);
        if (!isUnique && mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          _showErrorDialog('Oh dear, this username is already taken. Please choose another.');
          return;
        }

        // Update Firestore
        await _firestore.collection('users').doc(user!.uid).set({
          'fullName': _nameController.text,
        }, SetOptions(merge: true));

        // Update Firebase Auth display name
        await user!.updateDisplayName(_nameController.text);
      }

      // Upload Avatar
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child('avatars').child('${user!.uid}.jpg');
        await storageRef.putFile(_imageFile!);
        final photoURL = await storageRef.getDownloadURL();
        await user!.updatePhotoURL(photoURL);

        // Update Firestore with photo URL
        await _firestore.collection('users').doc(user!.uid).set({
          'photoURL': photoURL,
        }, SetOptions(merge: true));
      }

      // Reload userto get updated information
      await user!.reload();

      // Call the callback function to notify profile update
      widget.onProfileUpdated();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSuccessDialog('Your profile is now as enchanting as your smile!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog('Oops, something went wrong. Please try again later.');
      }
    }
  }


  Future<bool> _isUsernameUnique(String username) async {
    final result = await _firestore
        .collection('users')
        .where('fullName', isEqualTo: username)
        .get();
    return result.docs.isEmpty;
  }

  Future<void> _verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await user!.updatePhoneNumber(credential);
        // Update Firestore with phone number
        await _firestore.collection('users').doc(user!.uid).set({
          'phoneNumber': _phoneController.text,
        }, SetOptions(merge: true));
        setState(() {
          _isPhoneNumberVerified = true; // Update verification status
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        _showErrorDialog(e.message!);
      },
      codeSent: (String verificationId, int? resendToken) async {
        // Prompt the user to enter the code sent to their phone
        String smsCode = await _showSmsCodeDialog();

        // Create a PhoneAuthCredential with the code
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

        // Update the user's phone number
        await user!.updatePhoneNumber(credential);
        // Update Firestore with phone number
        await _firestore.collection('users').doc(user!.uid).set({
          'phoneNumber': _phoneController.text,
        }, SetOptions(merge: true));
        setState(() {
          _isPhoneNumberVerified = true; // Update verification status
        });

        // Clear the text field after verification
        _phoneController.clear();

        // Show success message
        _showSuccessDialog('Your phone number is now as verified as our love!');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _showErrorDialog('Verification code auto-retrieval timed out. Please try again, my love.');
      },
    );
  }

  Future<String> _showSmsCodeDialog() async {
    String smsCode = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter SMS Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              onChanged: (value) {
                smsCode = value;
              },
            ),
          ],
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Submit'),
            onPressed: () {
              Navigator.of(context).pop(smsCode);
            },
          ),
        ],
      ),
    );

    return smsCode;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioPlayerService, child) {
        return StreamBuilder(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              var userDoc = snapshot.data!;_nameController.text = userDoc['fullName'] ?? '';
              // Get phone number from Firestore if not verified
              if (!_isPhoneNumberVerified) {
                _phoneController.text = userDoc['phoneNumber'] ?? '';
              }

            }
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                  ),
                ),
                backgroundColor: Colors.pink[300],
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.pink[100]!, Colors.white],
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView( // To handle overflow if content is too long
                  child: Column(
                    children: <Widget>[
                      // Profile Settings Card
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: <Widget>[
                              if (user != null)
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(user!.photoURL ?? ''),
                                ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Change Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              if
                              (!_isPhoneNumberVerified) // Show phone number field only if not verified
                              TextField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              if (!_isPhoneNumberVerified) // Show verify button only if not verified
                              ElevatedButton(
                                onPressed: _verifyPhoneNumber,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[200],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text('Verify Phone Number'),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text('Change Avatar'),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton.icon(
                                onPressed: _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                icon: const Icon(Icons.favorite), // Heart icon
                                label: const Text('Save Changes'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Music Controls Card
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: <Widget>[
                              const Text(
                                'Music Controls',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  audioPlayerService.isPlaying
                                      ? audioPlayerService.pauseBackgroundMusic()
                                      : audioPlayerService.playBackgroundMusic();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: Text(audioPlayerService.isPlaying ? 'Pause Music' : 'Play Music'),
                              ),
                              const SizedBox(height: 15),
                              Slider(
                                value: audioPlayerService.currentVolume,
                                onChanged: (value) => audioPlayerService.setVolume(value),
                                min: 0.0,
                                max: 1.0,
                                activeColor: Colors.pink[300],
                                inactiveColor: Colors.pink[100],
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: audioPlayerService.stopBackgroundMusic,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[200],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text('Stop Music'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}