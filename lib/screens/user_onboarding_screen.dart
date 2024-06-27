import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:mylove/screens/navigate.dart';
import 'package:uuid/uuid.dart';
import 'package:mylove/page/profile_page.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({super.key});

  @override
  State <UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();// Controller for "About Me"
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'US'); // Default country code
  File? _imageFile;
  bool _isLoading = false; // To show loading indicator
  String? photoURL; // To store the Google photo URL

  late AnimationController _animationController; // Animation controller
  late Animation<double> _fadeAnimation; // Fade animation


  @override
  void initState() {
    super.initState();
    _checkExistingData(); // Check if user data exists on startup
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Define fade animation
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start the animation after a delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  Future<void> _checkExistingData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        if(mounted) {
          // User data already exists, navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MyHomePage(onReturn: () {},
                  name: docSnapshot.get('fullName') ?? '',
                  userId: docSnapshot.get('userId') ?? '',
                  email: user.email ?? '', // Use emailfrom FirebaseAuth if available
                  aboutMe: docSnapshot.get('aboutMe') ?? '',
                  photoURL: docSnapshot.get('photoURL'), // Pass photoURL
                  onDataUpdated: (newName, newPhotoURL) {
                    // Empty callback - no action needed here
                  },
                ),

            ),
          );
        }
      } else {
        // User data doesn't exist, proceed with onboarding
        _prefillData();
      }
    }
  }

  void _prefillData() {
    final User? user = _auth.currentUser;
    if (user != null) {
      if (user.providerData.any((provider) => provider.providerId == 'google.com')) {
        // User signed in with Google
        _nameController.text = user.displayName ?? '';
        photoURL = user.photoURL; // Get photo URL from Google
        setState(() {}); // Update the UI to show the image
        // You might want to pre-fill email and avatar here as well
      } else if (user.providerData.any((provider) => provider.providerId == 'facebook.com')) {
        // User signed in with Facebook
        // Fetch and pre-fill Facebook data here
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
      photoURL = null; // Clear Google photo URL if user picks a new one
    });
  }

  Future<void> _submitUserData() async {
    if (_imageFile == null && photoURL == null) {
      // Show an error message or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share a glimpse of your lovely self!')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final User? user = _auth.currentUser;
    if (user != null) {

      if (_imageFile != null) {
        // Upload avatar to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
        final uploadTask = storageRef.putFile(_imageFile!);
        await uploadTask.whenComplete(() async {
          photoURL = await storageRef.getDownloadURL();
        });
      }

      //Generate a unique ID for the user
      var uuid = const Uuid();
      String uniqueId = uuid.v4();
      // Create searchKeywords array
      List<String> searchKeywords = [];
      searchKeywords.add(uniqueId.toLowerCase()); // Add the lowercase userId
      searchKeywords.addAll(_nameController.text.toLowerCase().split(' ')); // Add lowercase name words

      // Store user data in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': _nameController.text,
        'phoneNumber': _phoneNumber.phoneNumber,
        'photoURL': photoURL, // Store avatar URL if available
        'userId': uniqueId, // Store the generated unique ID
        'searchKeywords': searchKeywords, // Store the searchKeywords array
        'aboutMe': _aboutMeController.text, // Store "About Me"
      }, SetOptions(merge: true)); // Merge with existing data if any

      // Navigate to the main screen
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      if(mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(onReturn: () {},
          name: _nameController.text,
          userId: uniqueId,
          email: user.email ?? '', // Handle potential null email
          aboutMe: _aboutMeController.text,
          photoURL: photoURL,
            onDataUpdated: (newName, newPhotoURL) {
              // Simplified callback for name and photo
              setState(() {
                _nameController.text = newName;
                photoURL = newPhotoURL;
              });
            },
        ),
          ),// Pass the photoURL if available)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Us More About You'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // To handle keyboard overflow
          child: FadeTransition( // Wrap the form with FadeTransition
            opacity: _fadeAnimation,
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Lovely Name',
                    hintText: 'So we can call you by it...',),
                ),
                const SizedBox(height: 16),
                InternationalPhoneNumberInput(
                  onInputChanged: (PhoneNumber number) {
                    _phoneNumber = number;
                  },
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                  ),
                  ignoreBlank: false,
                  autoValidateMode: AutovalidateMode.disabled,
                  selectorTextStyle: const TextStyle(color: Colors.black),
                  initialValue: _phoneNumber,
                  textFieldController: _phoneNumberController,
                  formatInput: true,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  inputBorder: const OutlineInputBorder(),
                  onSaved: (PhoneNumber number) {
                    print('On Saved: $number');
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Share a photo, so we can recognize you!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                if (photoURL != null)
                  Image.network(
                      photoURL!, height: 100) // Show Google photo if available
                else
                  if (_imageFile != null)
                    Image.file(_imageFile!, height: 100)
                  else
                    const Placeholder(fallbackHeight: 100),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Choose Avatar'),
                ),
                const SizedBox(height: 32),
                // "About Me" field
                TextFormField(
                  controller: _aboutMeController,
                  decoration: const InputDecoration(
                    labelText: 'About Me',
                    hintText: 'Tell us a little about yourself...',
                  ),
                  maxLines: 3, // Allow multiple lines for "About Me"
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitUserData,
                  child: _isLoading
                      ? const CircularProgressIndicator() // Show loading indicator
                      : const Text('Submit'),
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }

@override
void dispose() {
  _animationController.dispose(); // Dispose the animation controller
  super.dispose();
}
}