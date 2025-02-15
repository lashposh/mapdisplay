import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomePage extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance;

  UserHomePage({super.key});

  Future<void> confirmBroadcast(String broadcastId) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // First, get the user's location from their profile
      final userSnapshot =
          await _database.ref().child('users').child(currentUser.uid).get();

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(
            userSnapshot.value as Map<dynamic, dynamic>);

        // Store confirmation with location data and userId
        await _database
            .ref()
            .child('broadcasts')
            .child(broadcastId)
            .child('confirmations')
            .child(currentUser.uid)
            .set({
          'timestamp': ServerValue.timestamp,
          'userEmail': currentUser.email,
          'name': userData['name'],
          'location': userData['location'],
          'userId': currentUser.uid,
          'isCollected': false,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home Page'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User Welcome Section
          StreamBuilder(
            stream: _database
                .ref()
                .child('users')
                .child(currentUser?.uid ?? '')
                .onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                );
              }

              final userData = Map<String, dynamic>.from(
                  userSnapshot.data!.snapshot.value as Map);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Welcome, ${userData['name']}!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              );
            },
          ),

          // Notifications Section
          StreamBuilder(
            stream: _database
                .ref()
                .child('notifications')
                .orderByChild('userEmail')
                .equalTo(currentUser?.email)
                .onValue,
            builder:
                (context, AsyncSnapshot<DatabaseEvent> notificationSnapshot) {
              if (notificationSnapshot.hasData &&
                  notificationSnapshot.data?.snapshot.value != null) {
                Map<dynamic, dynamic> notifications =
                    Map<dynamic, dynamic>.from(
                        notificationSnapshot.data!.snapshot.value as Map);

                List<MapEntry<dynamic, dynamic>> notificationList =
                    notifications.entries.toList();

                // Sort notifications by timestamp in descending order
                notificationList.sort((a, b) => (b.value['timestamp'] as int)
                    .compareTo(a.value['timestamp'] as int));

                if (notificationList.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Updates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (var notification in notificationList.take(3))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notification.value['message'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // Broadcasts Section
          Expanded(
            child: StreamBuilder(
              stream: _database
                  .ref()
                  .child('broadcasts')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text('No broadcasts available'));
                }

                Map<dynamic, dynamic> broadcasts = Map<dynamic, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);

                List<MapEntry<dynamic, dynamic>> broadcastList =
                    broadcasts.entries.toList();

                broadcastList.sort((a, b) => (b.value['timestamp'] as int)
                    .compareTo(a.value['timestamp'] as int));

                return ListView.builder(
                  itemCount: broadcastList.length,
                  itemBuilder: (context, index) {
                    final broadcast = broadcastList[index].value;
                    final broadcastId = broadcastList[index].key;
                    final timestamp = DateTime.fromMillisecondsSinceEpoch(
                        broadcast['timestamp'] as int);
                    final formattedDate =
                        DateFormat('MMM dd, yyyy HH:mm').format(timestamp);

                    final confirmations =
                        broadcast['confirmations'] as Map? ?? {};
                    final hasConfirmed =
                        confirmations.containsKey(currentUser?.uid);
                    final isCollected = hasConfirmed &&
                        confirmations[currentUser?.uid]['isCollected'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              broadcast['title'] ?? 'No Title',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(broadcast['message'] ?? 'No Message'),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!hasConfirmed)
                                  ElevatedButton(
                                    onPressed: () =>
                                        confirmBroadcast(broadcastId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Confirm Receipt'),
                                  ),
                                if (hasConfirmed && !isCollected)
                                  Text(
                                    'Confirmed ✓',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (isCollected)
                                  Text(
                                    'Waste Collected ✓',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
