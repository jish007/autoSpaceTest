import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/ParkingProvider.dart';
import '../maps/datatime.dart';
import '../maps/maps.dart';

class TomTomRoutingPage extends StatefulWidget {
  final LatLng currentLocation;
  final Function(List<LatLng>) onRouteUpdated;
  final Map<String, dynamic> parkingSpot;
  final List<Map<String, dynamic>> parkingLocations;

  const TomTomRoutingPage({
    Key? key,
    required this.currentLocation,
    required this.onRouteUpdated,
    required this.parkingSpot,
    required this.parkingLocations
  }) : super(key: key);

  @override
  _TomTomRoutingPageState createState() => _TomTomRoutingPageState();
}

class _TomTomRoutingPageState extends State<TomTomRoutingPage> {
  late MapController _mapController;
  late TextEditingController _searchController;
  List<LatLng> _routeCoordinates = [];
  LatLng? _destination;

  bool isLoading = true;
  String? errorMessage;

  // List of parking locations
  /*List<Map<String, dynamic>> parkingLocations = [
    {
      "name": "Pranav Parking",
      "location": LatLng(9.3906, 76.5583),
      "isVisible": true,
    },
    {
      "name": "Gedi Parking",
      "location": LatLng(9.4000, 76.5650),
      "isVisible": true,
    },
    {
      "name": "Railway Station Parking",
      "location": LatLng(9.4050, 76.5700),
      "isVisible": true,
    },
    {
      "name": "Airth Parking Zone",
      "location": LatLng(9.6001, 76.3805),
      "isVisible": true,
    },
    {
      "name": "Auto Spaxe chengannur",
      "location": LatLng(9.3155, 76.6158),
      "isVisible": true,
    },
  ];*/

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController(text: widget.parkingSpot['name']);
  }

  // Function to calculate the route and update the map with polyline
  Future<void> _calculateRoute(LatLng destination) async {
    try {
      List<LatLng> route = await _getRouteFromTomTom(widget.currentLocation, destination);

      widget.onRouteUpdated(route); // Route updated for HomeScreen callback
      setState(() {
        _routeCoordinates = route;
        _destination = destination;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating route: $e')),
      );
    }
  }


  // Function to fetch route from TomTom API
  Future<List<LatLng>> _getRouteFromTomTom(LatLng start, LatLng end) async {
    String apiKey = '8CKwch3uCDAuLbcrffLiAx8IdhU9bGKS';
    String url = 'https://api.tomtom.com/routing/1/calculateRoute/${start.latitude},${start.longitude}:${end.latitude},${end.longitude}/json?key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      List<dynamic> geometry = data['routes'][0]['legs'][0]['points'];
      List<LatLng> routeCoordinates = geometry.map((point) {
        return LatLng(point['latitude'], point['longitude']);
      }).toList();

      return routeCoordinates;
    } else {
      throw Exception('Failed to load route');
    }
  }

  // Function to handle location search
  void _onSearchDestination() {
    String input = _searchController.text.trim();

    var matchedParking = widget.parkingLocations.firstWhere(
          (parking) => parking['name'].toLowerCase() == input.toLowerCase(),
      orElse: () => {}, // Prevent crashes if no match is found
    );

    if (matchedParking.isNotEmpty) {
      // Extracting coordinates correctly from `parkingSpot`
      if (widget.parkingSpot.containsKey('location')) {
        var locationStr = widget.parkingSpot['location'].toString().split(',');
        if (locationStr.length == 2) {
          double? latitude = double.tryParse(locationStr[0].trim());
          double? longitude = double.tryParse(locationStr[1].trim());

          if (latitude != null && longitude != null) {
            LatLng parkingLocation = LatLng(latitude, longitude);
            _calculateRoute(parkingLocation);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid coordinates format.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location format error.')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parking area not found.')),
      );
    }
  }

  // Update visibility of parking markers based on zoom level
  void _updateMarkerVisibility(double zoomLevel) {
    setState(() {
      for (var parking in widget.parkingLocations) {
        parking['isVisible'] = zoomLevel > 13.5; // Fix visibility logic
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.green.shade50,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the home page
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildMap(),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // Build the search bar to input a destination
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter parking area name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                filled: true, // Adds background color to the TextField
                hintStyle: TextStyle(color: const Color.fromARGB(255, 156, 90, 90)), // Set hint text color to white for contrast
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Color.fromARGB(255, 0, 0, 0)), // Set icon color to white
                  onPressed: _onSearchDestination, // Search action on click
                ),
              ),
              onSubmitted: (value) => _onSearchDestination(), // Trigger search on 'Enter'
            ),
          ),
        ],
      ),
    );
  }

  // Build the map for displaying the route and parking markers
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.currentLocation,
        initialZoom: 15,
        onPositionChanged: (position, hasGesture) {
          if (position != null) {
            _updateMarkerVisibility(position.zoom ?? 15);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=8CKwch3uCDAuLbcrffLiAx8IdhU9bGKS',
          userAgentPackageName: 'com.example.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routeCoordinates,
              strokeWidth: 6,
              color: const Color.fromARGB(255, 247, 2, 2),
            ),
          ],
        ),
        MarkerLayer(
          markers: widget.parkingLocations.map((parking) {
            return Marker(
              point: parking["location"],
              width: 150,
              height: parking["isVisible"] == true ? 80 : 0,
              child: parking["isVisible"] == true
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 40),
                  const SizedBox(height: 5),
                  Text(
                    parking["name"],
                    style: const TextStyle(
                      color: Color.fromARGB(255, 117, 35, 35),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> storeFare(String fare) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ratePerHour', fare);
  }

  // Build the bottom button
  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          try {
            if (widget.parkingSpot.isNotEmpty) {
              // Update the ParkingProvider with the fetched details
              storeFare(widget.parkingSpot['ratePerHour'].toString());
              Provider.of<ParkingProvider>(context, listen: false).setParkingSpot(
                name: widget.parkingSpot['name'].toString(),
                description: widget.parkingSpot['description'].toString(),
                imageUrl: widget.parkingSpot['imageUrl'],
                parkingLocation: widget.parkingSpot['location'].toString(),
                ratePerHour: widget.parkingSpot['ratePerHour'].toString(),
                adminMailId: widget.parkingSpot['adminMailId'].toString(),
              );

              Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => /*DateTimeRangePickerScreen(
                          parkingId: widget.parkingId,
                        ),*/
                        SvgUpdater(parkingSpot: widget.parkingSpot),
                      ),
                    );
            } else {
              print("No parking spot found with name:");
            }
          } catch (e) {
            print("Error fetching parking spot: $e");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Text(
          "ParkingMap",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}