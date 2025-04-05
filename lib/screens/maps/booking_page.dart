import 'dart:convert';

import 'package:autospaxe/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../providers/ParkingProvider.dart';
import 'booking_page_wigets.dart';

class BookingPage extends StatefulWidget {
  final String slotId;
  final String slotType;
  final String slotNumber;
  final int fare;
  final DateTime? endDate;
  final String startTime;
  final String endTime;

  const BookingPage({
    super.key,
    required this.slotNumber,
    required this.slotType,
    required this.slotId,
    required this.fare,
    required this.endDate,
    required this.endTime,
    required this.startTime
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final double _maxSlideHeight = 0.735;
  final double _minSlideHeight = 0.735;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();
  bool _imagesVisible = false;
  bool _isVehicleMenuExpanded = false;
  late VehicleOption _selectedVehicle;
  late BookingData bookingData;

  List<Map<String, dynamic>> vehicleDataList = [];

  static const String baseUrl = 'http://localhost:9000';

  // Sample parking images - in a real app, these would come from bookingData
  final List<String> parkingImages = const [
    "https://picsum.photos/800/400",
    "https://picsum.photos/800/401",
    "https://picsum.photos/800/402",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: _maxSlideHeight,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Initialize bookingData with default values
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    // Initialize with empty vehicle options - will be populated after API call
    bookingData = BookingData(
      fromLocation: 'Your current location',
      toLocation: parkingProvider.parkingName,
      parkingSlot: widget.slotNumber,
      parkingSlotId: widget.slotId,
      bookingTime: '${widget.startTime} - ${widget.endTime}',
      parkingName: parkingProvider.parkingName,
      parkingAddress: 'Current address',
      parkingRating: 4.7,
      parkingFare: widget.fare,
      vehicleOptions: [], // Empty initially, will be populated after API call
      bookingDate: widget.endDate,
    );

    // Add a default vehicle if needed for initial state
    _selectedVehicle = const VehicleOption(
      brand: 'Loading',
      model: '...',
      type: 'Please wait',
      vehicleNum: '...',
      vehicleType: '...',
      isDefault: true,
    );

    // Fetch user vehicles
    _fetchUserVehicles();

    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward().then((_) {
        setState(() => _imagesVisible = true);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void updateVehicleData(List<dynamic> apiResponse) {
    setState(() {
      vehicleDataList = List<Map<String, dynamic>>.from(apiResponse);

      // Transform API vehicle data to VehicleOption objects
      List<VehicleOption> vehicleOptions = [];
      for (int i = 0; i < vehicleDataList.length; i++) {
        final vehicle = vehicleDataList[i];
        vehicleOptions.add(
          VehicleOption(
            brand: vehicle['vehicleBrand'] ?? '',
            model: vehicle['vehicleModel'] ?? '',
            type: vehicle['vehicleGene'] ?? '',
            vehicleNum: vehicle['vehicleNumber'] ?? '',
            vehicleType: vehicle['vehicleType'] ?? '',
            isDefault: i == 0, // First vehicle is default
          ),
        );
      }

      // If no vehicles were returned from API, add a placeholder
      if (vehicleOptions.isEmpty) {
        vehicleOptions.add(
          const VehicleOption(
            brand: 'No vehicles',
            model: 'found',
            type: 'Please add a vehicle',
            vehicleNum: 'Not found',
            vehicleType: 'Not found',
            isDefault: true,
          ),
        );
      }

      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

      // Update BookingData object
      bookingData = BookingData(
        fromLocation: 'Your current location',
        toLocation: parkingProvider.parkingName,
        parkingSlot: widget.slotNumber,
        parkingSlotId: widget.slotId,
        bookingTime: '${widget.startTime} - ${widget.endTime}',
        parkingName: parkingProvider.parkingName,
        parkingAddress: 'Current address',
        parkingRating: 4.7,
        parkingFare: widget.fare,
        vehicleOptions: vehicleOptions,
        bookingDate: widget.endDate,
      );

      // Update selected vehicle
      _selectedVehicle = vehicleOptions.first; // Always safe since we ensure list is not empty
    });
  }

  void _fetchUserVehicles() async {
    try {
      // Replace with your actual API call
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String userEmail = userProvider.userEmail.toString();
      final response = await http.get(Uri.parse('$baseUrl/profiles/by-user-mail-id?userEmailId=$userEmail'));
      if (response.statusCode == 200) {
        final List<dynamic> apiResponse = json.decode(response.body);
        updateVehicleData(apiResponse);
      } else {
        // Handle error
        print('Failed to load user vehicles: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exception
      print('Exception when fetching user vehicles: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // Check if bookingData.vehicleOptions is empty
    bool isDataLoaded = bookingData.vehicleOptions.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Booking Confirmation",
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.deepPurple.shade50, Colors.grey.shade100],
              ),
            ),
          ),

          AnimatedOpacity(
            opacity: _imagesVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                child: _buildModernCarousel(),
              ),
            ),
          ),

          // Show loading indicator while data is being fetched
          if (!isDataLoaded)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Only show the sliding panel if data is loaded
          if (isDataLoaded)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: MediaQuery.of(context).size.height * _slideAnimation.value,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      double newValue = _slideAnimation.value - (details.delta.dy / MediaQuery.of(context).size.height);
                      newValue = newValue.clamp(_minSlideHeight, _maxSlideHeight);
                      _animationController.value = newValue / _maxSlideHeight;
                    },
                    onVerticalDragEnd: (details) {
                      if (_slideAnimation.value < _minSlideHeight) {
                        _animationController.animateTo(_minSlideHeight / _maxSlideHeight);
                      }
                    },
                    child: child,
                  ),
                );
              },
              child: BookingSlidingPanel(
                bookingData: bookingData,
                selectedVehicle: _selectedVehicle,
                isVehicleMenuExpanded: _isVehicleMenuExpanded,
                onVehicleMenuToggle: () => setState(() => _isVehicleMenuExpanded = !_isVehicleMenuExpanded),
                onVehicleSelected: (vehicle) => setState(() {
                  _selectedVehicle = vehicle;
                  _isVehicleMenuExpanded = false;
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernCarousel() {
    return Stack(
      children: [
        PageView.builder(
          controller: _imagePageController,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemCount: parkingImages.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, spreadRadius: -2)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  parkingImages[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.deepPurple.shade400,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text("Image not available", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 8,
              child: WaterflowDots(
                itemCount: parkingImages.length,
                currentIndex: _currentImageIndex,
                activeColor: Colors.deepPurple.shade600,
                inactiveColor: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// WaterflowDots widget for the carousel indicator - adding here since it was referenced
// but not defined in the original code
class WaterflowDots extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double spacing;

  const WaterflowDots({
    Key? key,
    required this.itemCount,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    this.dotSize = 8.0,
    this.spacing = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        return Container(
          width: dotSize,
          height: dotSize,
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentIndex ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}