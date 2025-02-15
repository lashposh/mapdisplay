import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mapscreen.dart';

class CollectorHomePage extends StatefulWidget {
  const CollectorHomePage({super.key});

  @override
  State<CollectorHomePage> createState() => _CollectorHomePageState();
}

class _CollectorHomePageState extends State<CollectorHomePage> {
  final _database = FirebaseDatabase.instance;
  Set<String> processingCollections = {}; // Track collections in progress

  Future<List<Map<String, dynamic>>> getAllConfirmations() async {
    List<Map<String, dynamic>> confirmations = [];

    try {
      final broadcasts = await _database.ref().child('broadcasts').get();

      if (broadcasts.exists) {
        final broadcastsMap = Map<String, dynamic>.from(
            broadcasts.value as Map<dynamic, dynamic>);

        for (var broadcast in broadcastsMap.values) {
          if (broadcast['confirmations'] != null) {
            final confirmationsMap = Map<String, dynamic>.from(
                broadcast['confirmations'] as Map<dynamic, dynamic>);

            for (var confirmation in confirmationsMap.values) {
              if (confirmation['location'] != null &&
                  confirmation['userEmail'] != null) {
                confirmations.add({
                  'userEmail': confirmation['userEmail'],
                  'name': confirmation['name'] ?? 'Unknown',
                  'latitude': confirmation['location']['latitude'],
                  'longitude': confirmation['location']['longitude'],
                  'timestamp':
                      confirmation['timestamp'] ?? DateTime.now().toString(),
                  'isCollected': confirmation['isCollected'] ?? false,
                  'userId': confirmation['userId'] ?? '',
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching confirmations: $e');
    }

    return confirmations;
  }

  Future<void> markAsCollected(
      BuildContext context, String userEmail, String userId) async {
    // Prevent multiple presses
    if (processingCollections.contains(userId)) {
      return;
    }

    setState(() {
      processingCollections.add(userId); // Add to processing set
    });

    try {
      // Update the confirmation status in the database
      final broadcasts = await _database.ref().child('broadcasts').get();

      if (broadcasts.exists) {
        final broadcastsMap = Map<String, dynamic>.from(
            broadcasts.value as Map<dynamic, dynamic>);

        for (var entry in broadcastsMap.entries) {
          if (entry.value['confirmations'] != null) {
            final confirmationsRef = _database
                .ref()
                .child('broadcasts')
                .child(entry.key)
                .child('confirmations')
                .child(userId);

            await confirmationsRef.update({
              'isCollected': true,
              'collectionTimestamp': ServerValue.timestamp,
              'collectorId':
                  FirebaseAuth.instance.currentUser?.uid, // Track who collected
            });
          }
        }
      }

      // Send notification to the user
      await _database.ref().child('notifications').push().set({
        'userEmail': userEmail,
        'message': 'Waste has been collected from your location.',
        'timestamp': ServerValue.timestamp,
        'type': 'collection_confirmation',
        'status': 'unread'
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Collection confirmed for $userEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Unable to confirm collection - $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Remove from processing set if there's an error
      setState(() {
        processingCollections.remove(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Dashboard'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.green.shade700,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'Confirmed Locations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Stream.fromFuture(getAllConfirmations()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final confirmations = snapshot.data ?? [];

                if (confirmations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No confirmations available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Confirmations: ${confirmations.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: confirmations.length,
                          itemBuilder: (context, index) {
                            final confirmation = confirmations[index];
                            final bool isCollected =
                                confirmation['isCollected'] ?? false;
                            final String userId = confirmation['userId'] ?? '';
                            final bool isProcessing =
                                processingCollections.contains(userId);

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          confirmation['userEmail'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Name: ${confirmation['name']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'Latitude: ${confirmation['latitude']}\nLongitude: ${confirmation['longitude']}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.map),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MapScreen(
                                              wardName: 'Location Details',
                                              confirmedLocations: [
                                                {
                                                  'latitude':
                                                      confirmation['latitude'],
                                                  'longitude':
                                                      confirmation['longitude'],
                                                  'name':
                                                      confirmation['userEmail'],
                                                }
                                              ],
                                              locationPoints: [
                                                '${confirmation['latitude']}, ${confirmation['longitude']}',
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: isCollected
                                        ? Text(
                                            'Collected ✓',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: isProcessing
                                                ? null // Disable button while processing
                                                : () => markAsCollected(
                                                    context,
                                                    confirmation['userEmail'],
                                                    userId),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: isProcessing
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Mark as Collected'),
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final confirmations = await getAllConfirmations();
          if (confirmations.isNotEmpty && context.mounted) {
            final locationPoints = confirmations.take(4).map((conf) {
              final lat = conf['latitude'].toString();
              final lng = conf['longitude'].toString();
              return '$lat, $lng';
            }).toList();

            while (locationPoints.length < 4) {
              locationPoints.add('');
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  wardName: 'All Locations',
                  confirmedLocations: confirmations
                      .map((conf) => {
                            'latitude': conf['latitude'],
                            'longitude': conf['longitude'],
                            'name': conf['userEmail'],
                          })
                      .toList(),
                  locationPoints: locationPoints,
                ),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No confirmations available to show on map')),
            );
          }
        },
        label: const Text('View All on Map'),
        icon: const Icon(Icons.map),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}
