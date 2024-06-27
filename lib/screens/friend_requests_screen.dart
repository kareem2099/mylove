import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  Future<void> _updateFriendRequest(String requestId, String status) async {
    await FirebaseFirestore.instance.collection('friendRequests').doc(requestId).update({
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: Colors.pink[300],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friendRequests')
            .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final requests = snapshot.data!.docs;
            if (requests.isEmpty) {
              return const Center(child: Text('No friend requests yet.'));
            }
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final requestDoc = requests[index];
                final requestId = requestDoc.id;
                final senderId = requestDoc.get('senderId');

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Loading...'),
                      );
                    }

                    if (userSnapshot.hasData) {
                      final userDoc = userSnapshot.data!;
                      final userName = userDoc['fullName'] ?? 'Unknown';
                      final userPhotoUrl = userDoc['photoURL'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                        ),
                        title: Text(userName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _updateFriendRequest(requestId, 'accepted'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _updateFriendRequest(requestId, 'rejected'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const ListTile(
                        title: Text('User not found.'),
                      );
                    }
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('No data found'));
          }
        },
      ),
    );
  }
}