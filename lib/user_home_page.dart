import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home Page'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome, User!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance
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

                // Sort by timestamp in descending order
                broadcastList.sort((a, b) => (b.value['timestamp'] as int)
                    .compareTo(a.value['timestamp'] as int));

                return ListView.builder(
                  itemCount: broadcastList.length,
                  itemBuilder: (context, index) {
                    final broadcast = broadcastList[index].value;
                    final timestamp = DateTime.fromMillisecondsSinceEpoch(
                        broadcast['timestamp'] as int);
                    final formattedDate =
                        DateFormat('MMM dd, yyyy HH:mm').format(timestamp);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        title: Text(
                          broadcast['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
