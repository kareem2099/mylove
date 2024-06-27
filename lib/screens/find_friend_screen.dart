import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _performSearch() {
    setState(() {});
  }

  Future<void> _sendFriendRequest(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final requestQuery = FirebaseFirestore.instance
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: userId);
      final requestSnapshot = await requestQuery.get();

      if (requestSnapshot.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('friendRequests').add({
          'senderId': currentUser.uid,
          'receiverId': userId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      } else {
        final requestDoc = requestSnapshot.docs.first;
        final requestStatus = requestDoc.get('status');

        if (requestStatus == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request already pending.')),
          );
        } else if (requestStatus == 'accepted') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are already friends.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Soulmate'),
        backgroundColor: Colors.pink[300],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (text) {
                setState(() {
                  _searchQuery = text;
                });
                _performSearch();
              },
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _searchQuery.isEmpty
                  ? FirebaseFirestore.instance.collection('users').snapshots()
                  : FirebaseFirestore.instance
                  .collection('users')
                  .where('searchKeywords', arrayContainsAny: _searchQuery.toLowerCase().split(' '))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  final users = snapshot.data!.docs;

                  return users.isEmpty
                      ? const Center(
                    child: Text('No users found.'),
                  )
                      : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userDoc = users[index];
                      final userName = userDoc['fullName'] ?? 'Unknown';
                      final userId = userDoc['userId'];
                      final userPhotoUrl = userDoc['photoURL'];

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('friendRequests')
                            .where('senderId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                            .where('receiverId', isEqualTo: userId)
                            .snapshots(),
                        builder: (context, requestSnapshot) {
                          if (requestSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Loading...'),
                            );
                          }

                          final requestDocs = requestSnapshot.data?.docs ?? [];
                          final requestStatus = requestDocs.isNotEmpty
                              ? requestDocs.first.get('status')
                              : null;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                            ),
                            title: Text(userName),
                            subtitle: Text('ID: $userId'),
                            trailing: requestStatus == 'pending'
                                ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text('Waiting'),
                            )
                                : requestStatus == 'accepted'
                                ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Friends'),
                            )
                                : ElevatedButton(
                              onPressed: () => _sendFriendRequest(userId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[300],
                              ),
                              child: const Text('Add'),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No data found'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}