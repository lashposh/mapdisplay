import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final String wardName;
  final List<Map<String, dynamic>> confirmedLocations;
  final List<String>? locationPoints;

  const MapScreen({
    super.key,
    required this.wardName,
    this.confirmedLocations = const [],
    this.locationPoints,
  });

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
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();

    // Set location points if provided
    if (widget.locationPoints != null && widget.locationPoints!.isNotEmpty) {
      if (widget.locationPoints!.isNotEmpty &&
          widget.locationPoints![0].isNotEmpty) {
        location1Controller.text = widget.locationPoints![0];
      }
      if (widget.locationPoints!.length > 1 &&
          widget.locationPoints![1].isNotEmpty) {
        location2Controller.text = widget.locationPoints![1];
      }
      if (widget.locationPoints!.length > 2 &&
          widget.locationPoints![2].isNotEmpty) {
        location3Controller.text = widget.locationPoints![2];
      }
      if (widget.locationPoints!.length > 3 &&
          widget.locationPoints![3].isNotEmpty) {
        location4Controller.text = widget.locationPoints![3];
      }

      // If we have at least one location, automatically plot the route
      if (widget.locationPoints!.any((location) => location.isNotEmpty)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _plotRoute();
        });
      }
    }

    // Add markers for all confirmed locations
    _addConfirmedLocationMarkers();
  }

  void _addConfirmedLocationMarkers() {
    for (var location in widget.confirmedLocations) {
      final lat = location['latitude'];
      final lng = location['longitude'];
      final name = location['name'];

      if (lat != null && lng != null) {
        setState(() {
          _markers.add(
            Marker(
              point: LatLng(lat is double ? lat : double.parse('$lat'),
                  lng is double ? lng : double.parse('$lng')),
              width: 80,
              height: 80,
              builder: (context) => Column(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    color: Colors.white.withOpacity(0.8),
                    child: Text(
                      name?.toString() ?? 'Unknown',
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      }
    }
  }

  // Function to plot route
  void _plotRoute() async {
    setState(() {
      _location1 = _parseCoordinates(location1Controller.text);
      _location2 = _parseCoordinates(location2Controller.text);
      _location3 = _parseCoordinates(location3Controller.text);
      _location4 = _parseCoordinates(location4Controller.text);
      _routePoints.clear(); // Clear the previous route points
    });

    // Create a list of valid locations
    final List<LatLng> validLocations = [];
    if (_location1 != null) validLocations.add(_location1!);
    if (_location2 != null) validLocations.add(_location2!);
    if (_location3 != null) validLocations.add(_location3!);
    if (_location4 != null) validLocations.add(_location4!);

    // Plot routes between consecutive valid locations
    for (int i = 0; i < validLocations.length - 1; i++) {
      await _fetchRoute(validLocations[i], validLocations[i + 1]);
    }
  }

  // Function to parse coordinates
  LatLng? _parseCoordinates(String input) {
    if (input.isEmpty) return null;

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

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          _routePoints.addAll(coordinates
              .map((coord) => LatLng(coord[1] as double, coord[0] as double)));
        });
      } else {
        print('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  // Get initial center point based on confirmed locations or default
  LatLng _getInitialCenter() {
    if (widget.confirmedLocations.isNotEmpty) {
      final firstLocation = widget.confirmedLocations.first;
      final lat = firstLocation['latitude'];
      final lng = firstLocation['longitude'];

      if (lat != null && lng != null) {
        return LatLng(lat is double ? lat : double.parse('$lat'),
            lng is double ? lng : double.parse('$lng'));
      }
    }

    // Try to use location1 if it's been set
    if (_location1 != null) {
      return _location1!;
    }

    // Default to Trivandrum coordinates
    return const LatLng(8.5061, 76.9683);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route for ${widget.wardName}'),
        backgroundColor: Colors.green.shade700,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  child: const Text('Show Route'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _getInitialCenter(),
                zoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: _markers,
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
