import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mylove/screens/quiz_screen.dart';
import 'package:mylove/screens/upload_screen.dart';
import 'package:mylove/screens/settings_screen.dart';
import 'package:mylove/page/auth_page.dart';

import '../page/profile_page.dart';
import 'find_friend_screen.dart';
import 'friend_requests_screen.dart';

class MyHomePage extends StatefulWidget {
  final VoidCallback onReturn;
  final String name;
  final String userId;
  final String email;
  final String aboutMe;
  final String? photoURL;
  final Function(String, String?) onDataUpdated; // Callback for name and photo


  const MyHomePage({super.key, required this.onReturn, required this.name, required this.userId, required this.email, required this.aboutMe, this.photoURL, required this.onDataUpdated});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  late Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
  }

  void _getCurrentUser() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  void _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  void _fetchUpdatedData() {
    // Fetch updated name and photoURL from Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((docSnapshot) {
      if (docSnapshot.exists) {
        String updatedName = docSnapshot.get('fullName') ?? '';
        String? updatedPhotoURL = docSnapshot.get('photoURL');

        // Call the callback to update UserOnboardingScreen
        widget.onDataUpdated(updatedName, updatedPhotoURL);
      }
    });
  }

  void _onProfileUpdated() {
    _getCurrentUser(); // Refresh the _user variable
  }

  @override
  Widget build(BuildContext context) {
    widget.onReturn();
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var userDoc = snapshot.data!;
              var userName = userDoc['fullName'] ?? 'Guest';
              return Text('Welcome $userName');
            } else {
              return const Text('Welcome Guest');
            }
          },
        ),
        backgroundColor: Colors.pink[300],
        // actions: [
        //   if (_user != null)
        //     Row(
        //       children: [
        //         CircleAvatar(
        //           backgroundImage: NetworkImage(_user!.photoURL ?? ''),
        //         ),
        //         const SizedBox(width: 8),
        //         PopupMenuButton(
        //           icon: const Icon(Icons.settings),
        //           onSelected: (value) {
        //             if (value == 'logout') {
        //               _signOut();
        //             } else if (value == 'settings') {
        //               Navigator.push(
        //                 context,
        //                 MaterialPageRoute(
        //                   builder: (context) => SettingsScreen(
        //                     onProfileUpdated: _onProfileUpdated,
        //                   ),
        //                 ),
        //               );
        //             }
        //           },
        //           itemBuilder: (context) => [
        //             const PopupMenuItem(
        //               value: 'settings',
        //               child: Text('Settings'),
        //             ),
        //             const PopupMenuItem(
        //               value: 'logout',
        //               child: Text('Logout'),
        //             ),
        //           ],
        //         ),
        //       ],
        //     ),
        // ],
      ),
      drawer: _user != null ? _buildDrawer() : null,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/first.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                  ),
                  child: const Text('Go to Quiz Screen'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UploadScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                  ),
                  child: const Text('Go to Memory Screen'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => const FuturePlanScreen()),
                    // );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                  ),
                  child: const Text('Future Plan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var userDoc = snapshot.data!;
                  var userName = userDoc['fullName'] ?? 'User';
                  return Text(userName);
                } else {
                  return const Text('hi cutie');
                }
              },
            ),
            accountEmail: Text(_user?.email ?? 'Email'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(_user?.photoURL ?? ''),
            ),
            decoration: BoxDecoration(
              color: Colors.pink[300],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person), // Or a suitable profile icon
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  ProfilePage(
                  name: widget.name,
                  userId: widget.userId,
                  email: widget.email,
                  aboutMe: widget.aboutMe,
                  photoURL: widget.photoURL,
                ),
              ),  ).then((_) {
                // After returning from ProfilePage, check for updates
                _fetchUpdatedData();
              });

            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Friend Requests'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to a new screen to handle friend requests
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendRequestsScreen(), // Create this screen
                ),
              );
            },
          ),
          ListTile( // New "Find Friends" option
            leading: const Icon(Icons.search), // Or a more romantic icon like Icons.favorite
            title: const Text('Find Your Soulmate'), // Romantic touch!
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,MaterialPageRoute(builder: (context) => const FindFriendsScreen()), // Navigate to the Find Friends screen
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onProfileUpdated: _onProfileUpdated,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

