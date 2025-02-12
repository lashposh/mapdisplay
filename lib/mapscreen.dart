import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final String wardName;

  const MapScreen({super.key, required this.wardName});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController location1Controller = TextEditingController();
  final TextEditingController location2Controller = TextEditingController();
  final TextEditingController location3Controller = TextEditingController();
  final TextEditingController location4Controller = TextEditingController();

  LatLng? _location1;
  LatLng? _location2;
  LatLng? _location3;
  LatLng? _location4;
  final List<LatLng> _routePoints = [];

  // Function to plot route
  void _plotRoute() async {
    setState(() {
      _location1 = _parseCoordinates(location1Controller.text);
      _location2 = _parseCoordinates(location2Controller.text);
      _location3 = _parseCoordinates(location3Controller.text);
      _location4 = _parseCoordinates(location4Controller.text);
      _routePoints.clear(); // Clear the previous route points
    });

    if (_location1 != null &&
        _location2 != null &&
        _location3 != null &&
        _location4 != null) {
      await _fetchRoute(_location1!, _location2!); // A to B
      await _fetchRoute(_location2!, _location3!); // B to C
      await _fetchRoute(_location3!, _location4!); // C to D
    }
  }

  // Function to parse coordinates
  LatLng? _parseCoordinates(String input) {
    final parts = input.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  // Function to fetch route from OSRM API
  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List coordinates =
          data['routes'][0]['geometry']['coordinates'] as List;

      setState(() {
        _routePoints.addAll(
            coordinates.map((coord) => LatLng(coord[1] as double, coord[0] as double)));
      });
    } else {
      print('Failed to fetch route');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route for ${widget.wardName}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Row for the two input text fields on the same line
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: location1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Location A (e.g., 8.5061, 76.9683)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: location2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Location B (e.g., 8.4961, 76.9590)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Row for the other two input text fields on the same line
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: location3Controller,
                        decoration: const InputDecoration(
                          labelText: 'Location C (e.g., 8.5061, 76.9600)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: location4Controller,
                        decoration: const InputDecoration(
                          labelText: 'Location D (e.g., 8.4950, 76.9500)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _plotRoute,
                  child: const Text('Show Route'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _location1 ?? const LatLng(8.5061, 76.9683),
                zoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.red,
                        strokeWidth: 4.0,
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
