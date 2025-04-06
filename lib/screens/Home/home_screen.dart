import 'dart:typed_data';

import 'package:autospaxe/screens/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import 'Details.dart';
import 'SearchPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

final double _fixedZoomLevel = 16.5;
final double minzoom = 20;
final LatLng _defaultLocation = LatLng(9.31741, 76.61764);

class HomeScreen extends StatefulWidget {
  final String? userMail;

  const HomeScreen({super.key, this.userMail});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

double _calculateDistance(LatLng start, LatLng end) {
  const double radius = 6371; // Radius of the Earth in km
  double lat1 = start.latitude * pi / 180;
  double lon1 = start.longitude * pi / 180;
  double lat2 = end.latitude * pi / 180;
  double lon2 = end.longitude * pi / 180;

  double dlat = lat2 - lat1;
  double dlon = lon2 - lon1;

  // Haversine formula
  double a = sin(dlat / 2) * sin(dlat / 2) +
      cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  // Distance in kilometers
  double distance = radius * c;

  return distance; // Return distance in kilometers
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ApiService apiService = ApiService();

  late Future<List<Map<String, dynamic>>> _futureParkingSpots;

  // Keep track of the current selected tab in the BottomNavigationBar
  int _currentIndex = 0;

  // List of screens or widgets you want to show for each tab
  final List<Widget> _screens = [
    // The screen containing the map
  ];

  // Function to change the tab
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  int _selectedIndex = 0;
  LatLng? _currentLocation;
  LatLng? _selectedLocation; // For storing selected destination location
  final Location _location = Location();
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  List<Polyline> _polylines = []; // For storing polylines between locations
  bool _locationPermissionGranted = false;
  bool _locationServiceSubscribed = false;
  bool _isMapReady = false;
  late final String parkingId;

  late List<Map<String, dynamic>> _parkingLocations = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Delay the Provider update to avoid the build-time setState issue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUserProvider(
            userEmail: widget.userMail.toString()
        );
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _fetchParkingSpots();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is a good place to re-check location when coming back to screen
    if (_locationPermissionGranted) {
      _refreshCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh location
      if (_locationPermissionGranted) {
        _refreshCurrentLocation();
        if (_isMapReady && _currentLocation != null) {
          _centerMapOnCurrentLocation();
        }
      }
    }
  }

  // New method to refresh current location on demand
  Future<void> _refreshCurrentLocation() async {
    try {
      LocationData locationData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
        // Center map if it's ready
        if (_isMapReady) {
          _centerMapOnCurrentLocation();
        }
      }
    } catch (e) {
      print("Error refreshing location: $e");
    }

    // Make sure we're subscribed to location updates
    if (!_locationServiceSubscribed) {
      _startLocationUpdates();
    }
  }

  // New method to center the map on current location
  void _centerMapOnCurrentLocation() {
    if (_currentLocation != null && _mapController.ready) {
      _mapController.move(_currentLocation!, _fixedZoomLevel);
    }
  }

  void _fetchParkingSpots() {
    _futureParkingSpots = apiService.getNearbyParkingSpots();

    _futureParkingSpots.then((spots) {
      if (mounted) {
        setState(() {
          _parkingLocations = spots.map((spot) {
            List<String> latLngStr = spot['location'].split(',');
            double latitude = double.parse(latLngStr[0].trim());
            double longitude = double.parse(latLngStr[1].trim());

            return {
              'name': spot['name'],
              'location': LatLng(latitude, longitude),
              'isVisible': true,
            };
          }).toList();
        });
      }
    }).catchError((error) {
      print("Error loading parking spots: $error");
    });
  }

  void _checkPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location service is disabled.")),
          );
        }
        return;
      }
    }

    PermissionStatus permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.granted ||
        permissionStatus == PermissionStatus.grantedLimited) {
      setState(() {
        _locationPermissionGranted = true;
      });
      _refreshCurrentLocation();
    } else {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus == PermissionStatus.granted ||
          permissionStatus == PermissionStatus.grantedLimited) {
        setState(() {
          _locationPermissionGranted = true;
        });
        _refreshCurrentLocation();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
        }
      }
    }
  }

  void _startLocationUpdates() {
    if (_locationServiceSubscribed) return;

    _locationServiceSubscribed = true;

    // Subscribe to location updates
    _location.onLocationChanged.listen((LocationData locationData) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    });
  }

  void _onButtonTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToSearchPage() async {
    if (_currentLocation != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TomTomRoutingPage(
            currentLocation: _currentLocation!,
            onRouteUpdated: _updateRoute,
            parkingSpot: {},
            parkingLocations: _parkingLocations,
          ),
        ),
      );

      // When returning from the search page, refresh location
      _refreshCurrentLocation();

      if (result != null && result is LatLng && mounted) {
        setState(() {
          _selectedLocation = result;
          _searchController.text =
          "Destination: ${result.latitude}, ${result.longitude}";
        });
        _addRoute(_currentLocation!, _selectedLocation!);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to fetch your current location.")),
        );
      }
    }
  }

  void _addRoute(LatLng start, LatLng destination) {
    setState(() {
      _polylines = [
        Polyline(
          points: [start, destination],
          strokeWidth: 4.0,
          color: Colors.blue,
        ),
      ];
    });
  }

  void _updateRoute(List<LatLng> routeCoordinates) {
    setState(() {
      _polylines = [
        Polyline(
          points: routeCoordinates,
          strokeWidth: 6,
          color: const Color.fromARGB(255, 243, 51, 33),
        ),
      ];
    });
  }

  void _updateMarkerVisibility(double zoomLevel) {
    setState(() {
      if (zoomLevel > 13.5) {
        _parkingLocations = _parkingLocations
            .map((parking) => {...parking, "isVisible": true})
            .toList();
      } else {
        _parkingLocations = _parkingLocations
            .map((parking) => {...parking, "isVisible": false})
            .toList();
      }
    });
  }

  void logout() async{
    final response = await apiService.logOutUser(widget.userMail.toString());
    if(response.statusCode == 200){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                logout();
              },
              color: Colors.black54,
            ),
            buildCardWithImageTextAndButton(),
            _buildMapView(),
            _buildSearchBar(),
            _buildNearbySpotsContainer(),
            _buildParkingSpotsList(context)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshCurrentLocation();
          _centerMapOnCurrentLocation();
        },
        child: Icon(Icons.my_location),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      height: 500, // Set a fixed height for the map view
      child: Center(
        child: _buildTomTomMap(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToSearchPage,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Search for parking...'
                              : _searchController.text,
                          style: TextStyle(
                            color: _searchController.text.isEmpty
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildCardWithImageTextAndButton() {
    return Container(
      margin: const EdgeInsets.all(20.0), // Margin around the container
      decoration: BoxDecoration(
        color: const Color.fromARGB(217, 55, 53, 53),
        borderRadius: BorderRadius.circular(16), // Rounded corners
        border: Border.all(color: const Color.fromARGB(38, 0, 0, 0), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(50, 0, 0, 0).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2), // Shadow position
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Image container

          // Row with icons and text
          Container(

            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Person icon on the left with background color
                Container(
                  padding: const EdgeInsets.all(8.0), // Padding around the icon
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 223, 224, 225), // Background color of the icon
                    shape: BoxShape.circle, // Circular shape
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: const Color.fromARGB(255, 140, 198, 7),
                    size: 30,
                  ),
                ),
                SizedBox(width: 16), // Space between icons
                // Location icon and text centered below the person icon
                Column(
                  children: [
                    // Location icon

                    SizedBox(height: 4), // Space between icon and text
                    // Location text
                    Text(
                      'Chengannur',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Spacer(), // Spacer to push the notification icon to the right
                // Notification icon on the right with background color
                Container(
                  padding: const EdgeInsets.all(8.0), // Padding around the icon
                  decoration: BoxDecoration(
                    color: Colors.green, // Background color of the icon
                    shape: BoxShape.circle, // Circular shape
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

              ],
            ),
          ),
          // Random text or content

          Padding(
            padding: EdgeInsets.only(bottom: 30,left: 20),

            child: Row(


              children: [
                Column(

                  children: [
                    Text(
                        'Welcome ${widget.userMail}',
                        style: GoogleFonts.openSans(
                          fontSize: 22,
                          color: const Color.fromARGB(255, 242, 244, 245),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left),
                  ],
                ),
              ],
            ),
          )
          // Button container

        ],
      ),
    );
  }

  Widget _buildTomTomMap() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(38, 0, 0, 0), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(50, 0, 0, 0).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation ?? _defaultLocation,
            initialZoom: _fixedZoomLevel,
            minZoom: 13,
            maxZoom: 20,
            onMapReady: () {
              setState(() {
                _isMapReady = true;
              });
              // Move to current location when map is ready if available
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, _fixedZoomLevel);
              } else {
                // If location not available yet, try to get it now
                _refreshCurrentLocation();
              }
            },
            onPositionChanged: (position, hasGesture) {
              // Adjust the visibility based on zoom level
              if (_mapController.zoom <= 13) {
                _updateMarkerVisibility(13);
              } else {
                _updateMarkerVisibility(_mapController.zoom);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=8CKwch3uCDAuLbcrffLiAx8IdhU9bGKS',
              userAgentPackageName: 'com.example.app',
            ),
            // Add a marker for current location
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                ],
              ),
            // Add markers for parking locations
            MarkerLayer(
              markers: _parkingLocations.map((parking) {
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
                          color: Color.fromARGB(255, 230, 12, 12),
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
            PolylineLayer(
              polylines: _polylines,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(int index, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () => _onButtonTap(index),
        child: Card(
          color: _selectedIndex == index
              ? const Color.fromARGB(255, 69, 204, 255)
              : Colors.grey[300],
          elevation: 3,
          child: Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              children: [
                Icon(icon, color: _selectedIndex == index ? Colors.white : Colors.black),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: _selectedIndex == index ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbySpotsContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearby Parking Spots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'View nearby parking spots and choose the best option.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRoutePage(BuildContext context, Map<String, dynamic> parkingSpot) async {
    if (_currentLocation == null) {
      await _refreshCurrentLocation();

      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Current location not available. Please wait.")),
        );
        return;
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TomTomRoutingPage(
          parkingLocations: _parkingLocations,
          currentLocation: _currentLocation!,
          parkingSpot: parkingSpot,
          onRouteUpdated: (route) {
            // Handle route update here if needed
            if (mounted) {
              _updateRoute(route);
            }
          },
        ),
      ),
    );

    // When returning from route page, refresh location and center map
    _refreshCurrentLocation();
  }

  Widget _buildParkingSpotsList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureParkingSpots,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No nearby parking spots found"));
        }

        final parkingSpots = snapshot.data!;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: parkingSpots.length,
            itemBuilder: (context, index) {
              final parkingSpot = parkingSpots[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 33, 33, 33),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(105, 0, 0, 0).withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                height: screenWidth < 600 ? 250 : 200,
                width: screenWidth * 0.9,

                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        convertToImage(parkingSpot['imageUrl']),
                        width: screenWidth < 600 ? 100 : 150,
                        height: screenWidth < 600 ? 190 : 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image_not_supported, size: 120),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            parkingSpot['name']!,
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parkingSpot['description']!,
                            style: TextStyle(
                              fontSize: screenWidth < 600 ? 12 : 14,
                              color: Color.fromARGB(255, 246, 245, 245),
                            ),
                            maxLines: screenWidth < 600 ? 8 : 10,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  _navigateToRoutePage(
                                    context,
                                    parkingSpot,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth < 600 ? 20 : 30,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text('Direction'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to details page
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => DetailsScreen(parkingSpot: parkingSpot)
                                      )
                                  ).then((_) {
                                    // Refresh location when returning from details page
                                    _refreshCurrentLocation();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth < 600 ? 20 : 30,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text('Details'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Uint8List convertToImage(imageBase64) {
    return Base64Decoder().convert(imageBase64);
  }
}

// Extension with proper implementation to check if map controller is ready
extension MapControllerExtension on MapController {
  bool get ready => camera != null;

  double get zoom {
    if (camera == null) return 16.5; // Default zoom level
    return camera!.zoom;
  }
}