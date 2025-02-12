import 'package:flutter/material.dart';
import 'mapscreen.dart'; // Import the MapScreen page

class CollectorHomePage extends StatelessWidget {
  const CollectorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Home Page'),
        backgroundColor: Colors.green.shade700,
        elevation: 0, // Remove shadow for a cleaner look
      ),
      body: Column(
        children: [
          // Top bar with user icon and welcome message
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.green.shade700,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'Welcome, Collector!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40), // Space between top bar and options

          // Column with 2x2 grid of buttons
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // First row of buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: WardButton(ward: 'Ward 1'),
                    ),
                    SizedBox(width: 10), // Reduced space between buttons
                    Expanded(
                      child: WardButton(ward: 'Ward 2'),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Space between rows

                // Second row of buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: WardButton(ward: 'Ward 3'),
                    ),
                    SizedBox(width: 10), // Reduced space between buttons
                    Expanded(
                      child: WardButton(ward: 'Ward 4'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WardButton extends StatelessWidget {
  final String ward;

  const WardButton({super.key, required this.ward});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Navigate to MapScreen and pass the ward name
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(wardName: ward),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), // Halved padding for smaller button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        ward,
        style: const TextStyle(
          fontSize: 14, // Reduced font size to match the smaller button size
          fontWeight: FontWeight.bold, // Bold text
          color: Colors.white, // White text color
        ),
      ),
    );
  }
}
