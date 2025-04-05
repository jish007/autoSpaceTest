import 'dart:async';
import 'dart:convert';
import 'package:autospaxe/providers/ParkingProvider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'date_time_picker_page.dart';

class SvgUpdater extends StatefulWidget {
  final Map<String, dynamic> parkingSpot;

  const SvgUpdater({
    Key? key,
    required this.parkingSpot,
  }) : super(key: key);

  @override
  _SvgUpdaterState createState() => _SvgUpdaterState();
}

class _SvgUpdaterState extends State<SvgUpdater> {
  static const String baseUrl = 'http://localhost:9000';

  int selectedImageIndex = -1;
  final int numRows = 26;
  final double labelSpacing = 4.0;

  List<Map<String, dynamic>> mockSlots = [];
  Map<String, double> slotProgress = {};
  Map<String, Duration> slotTimers = {};
  Map<String, Duration> slotInitialTimes = {};
  String? selectedSlotId;
  Timer? progressTimer;
  Offset dragOffset = Offset(0, 0);
  double dragSensitivity = 3.0;
  String selectedVehicleType = "any";
  List<Map<String, dynamic>> parkingSlots = [];
  String errorMessage = "";
  bool showErrorImage = false;

  @override
  void initState() {
    super.initState();
    startAutoRefresh();

    // Fetch slots from API and load them
    refreshData();
    startProgressUpdates();
    // Start progress updates
    startProgressUpdates();
    progressUpdatesCount++;
  }


  int progressUpdatesCount = 0;

  void startAutoRefresh() {
    const int maxProgressUpdates = 2;
    const Duration autoRefreshInterval = Duration(seconds: 2);
    Timer.periodic(autoRefreshInterval, (timer) {
      refreshData();
      if (progressUpdatesCount < maxProgressUpdates) {
        startProgressUpdates();
        progressUpdatesCount++;
      }
      if (progressUpdatesCount >= maxProgressUpdates) {
        timer.cancel(); // Stop the timer after the maximum number of updates
      }
    });
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    super.dispose();
  }

  Duration parseDuration(String timeStr) {
    List<String> parts = timeStr.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  Future<void> refreshData() async {
    try {
      setState(() {
        errorMessage = 'Refreshing...'; // Show a refreshing message
        showErrorImage = false;
      });

      // Fetch slots from API and load them
      await fetchParkingDetails().then((_) async {
        if (parkingSlots.isNotEmpty) {
          await loadJson(jsonEncode(parkingSlots)); // Pass fetched slots
          startProgressUpdates(); // Start the timer after data is loaded
        }
      });

      setState(() {
        errorMessage = ''; // Clear the refreshing message
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to refresh. Please try again later.';
        showErrorImage = true; // Show error image
      });
      print("Error refreshing data: $e");
    }
  }

  /*Future<void> printUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); // Retrieve the user ID
    if (userId != null) {
      print('User ID: $userId');
    } else {
      print('User ID not found');
    }
  }*/

  /*Future<void> saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }*/

  /*Future<void> holdSlot(String slotId, String userId) async {
    // Define the base URL
    String baseUrl = 'http://localhost:8080/api/parking-slots/$slotId/hold';

    // Define the query parameters
    Map<String, String> queryParams = {
      'userId': userId,
    };

    // Construct the full URL with query parameters
    Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    // Make the PATCH request
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    // Check the response status code
    if (response.statusCode == 200) {
      print('Slot held successfully');
    } else {
      print('Failed to hold slot: ${response.body}');
    }
  }*/


  Future<void> fetchParkingDetails() async {
    try {
      String adminMailId = Provider.of<ParkingProvider>(context, listen: false).adminMailId.toString();

      if (adminMailId.isEmpty) {
        setState(() {
          errorMessage = 'Please select a parking area first';
          showErrorImage = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/slots?adminMailId=$adminMailId'),
      );

      if (response.statusCode == 200) {
        await loadJson(response.body); // Pass API response to loadJson
        setState(() {
          errorMessage = ''; // Clear any previous error messages
          showErrorImage = false; // Ensure no error image is shown
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parking details fetched successfully')),
        );
      } else {
        setState(() {
          errorMessage =
              'Failed to load parking details. Status code: ${response.statusCode}';
          showErrorImage = false; // Ensure no error image is shown
        });
      }
    } catch (e) {
      setState(() {
        showErrorImage = true; // Show error image
        errorMessage = 'An error occurred while fetching parking details.';
      });
      print("Error fetching parking spot: $e");
    }
  }

  Future<void> loadJson(String jsonData) async {
    try {
      List<dynamic> jsonResponse1 = jsonDecode(jsonData);

      List<Map<String, dynamic>> transformedData = jsonResponse1.map((spot) {
        // Convert all numeric values to strings to ensure consistency
        return {
          'range': spot['ranges']?.toString() ?? '',
          'x': spot['x']?.toString() ?? '0',
          'y': spot['y']?.toString() ?? '0',
          'id': spot['slotId']?.toString() ?? '',
          'status': spot['slotAvailability']?.toString() ?? 'false',
          'exitTime': spot['exitTime'],
          'startTime': spot['startTime'],
          'slotNumber': spot['slotNumber']?.toString() ?? '',
          'type': spot['vehicleType']?.toString().toLowerCase() ?? '',
          'availability': spot['slotAvailability'] == true,
          'hold': spot['hold'] == true,
          'reserved': spot['vehicleType']?.toString() ?? '',
          'width': spot['width']?.toString() ?? '40',
          'height': spot['height']?.toString() ?? '40',
        };
      }).toList();

      setState(() {
        double initialX = 2;
        double initialY = 50;
        double xIncrement = 159;
        double extraRangeGap = 80;
        int slotsPerRow = 18;
        double x = initialX;
        double y = initialY;
        String currentRange = '';

        mockSlots = [];
        List<Map<String, dynamic>> currentRangeSlots = [];

        for (var slot in transformedData) {
          String range = slot['range'] ?? '';
          List<String> rangeParts = range.split('-');
          int rangeStart = int.tryParse(rangeParts[0]) ?? 0;
          int rangeEnd = rangeParts.length > 1
              ? int.tryParse(rangeParts[1]) ?? 0
              : rangeStart;

          if (currentRange != range) {
            if (currentRangeSlots.isNotEmpty) {
              mockSlots.addAll(currentRangeSlots);
              currentRangeSlots.clear();
              x = initialX;
              y += extraRangeGap;
            }
            currentRange = range;
          }

          double tempX = x;
          double tempY = y;

          // Swap x and y
          double temp = tempX;
          tempX = tempY;
          tempY = temp;

          slot['x'] = tempX.toString();
          slot['y'] = tempY.toString();

          currentRangeSlots.add(slot);
          x += xIncrement;

          if (currentRangeSlots.length % slotsPerRow == 0) {
            x = initialX;
          }
        }

        if (currentRangeSlots.isNotEmpty) {
          mockSlots.addAll(currentRangeSlots);
        }

        // Initialize slot progress and timers
        for (var slot in mockSlots) {
          String slotId = slot['id'] ?? 'unknown';
          bool isAvailable = slot['availability'] == true;
          bool isHeld = slot['hold'] == true;

          if (!isAvailable && !isHeld) {
            DateTime? startTime = slot['startTime'] != null &&
                    slot['startTime'].toString().isNotEmpty
                ? parseDateTime(slot['startTime'])
                : null;
            DateTime? exitTime = slot['exitTime'] != null &&
                    slot['exitTime'].toString().isNotEmpty
                ? parseDateTime(slot['exitTime'])
                : null;
            DateTime now = DateTime.now();

            if (startTime != null && exitTime != null) {
              Duration totalDuration = exitTime.difference(startTime);
              Duration remainingTime = exitTime.difference(now);

              if (remainingTime.isNegative) {
                remainingTime = Duration.zero;
              }

              // Calculate progress as remaining time / total duration
              double progress = totalDuration.inSeconds > 0
                  ? remainingTime.inSeconds / totalDuration.inSeconds
                  : 0.0;

              slotProgress[slotId] = progress;
              slotTimers[slotId] = remainingTime;
              slotInitialTimes[slotId] = totalDuration;

              print(
                  'Slot $slotId: Total duration: $totalDuration, Remaining: $remainingTime, Progress: $progress');
            } else {
              slotProgress[slotId] = 0.0;
              slotTimers[slotId] = Duration.zero;
              slotInitialTimes[slotId] = Duration.zero;
            }
          } else {
            // For available or held slots, set timer to zero
            slotProgress[slotId] = 0.0;
            slotTimers[slotId] = Duration.zero;
            slotInitialTimes[slotId] = Duration.zero;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading JSON: $e');
    }
  }

  String formatRemainingTime(Duration duration) {
    if (duration == Duration.zero) return '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void startProgressUpdates() {
    progressTimer?.cancel();

    progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        for (var slot in mockSlots) {
          String slotId = slot['id'] ?? 'unknown';
          bool isAvailable = slot['availability'] == true;
          bool isHeld = slot['hold'] == true;

          if (!isAvailable && !isHeld) {
            Duration remainingTime = slotTimers[slotId] ?? Duration.zero;

            if (remainingTime > Duration.zero) {
              slotTimers[slotId] = remainingTime - const Duration(seconds: 1);

              // Get the initial total duration
              Duration initialTime = slotInitialTimes[slotId] ?? Duration.zero;

              // Update progress
              if (initialTime.inSeconds > 0) {
                slotProgress[slotId] =
                    slotTimers[slotId]!.inSeconds / initialTime.inSeconds;
              } else {
                slotProgress[slotId] = 0;
              }
            } else {
              slotProgress[slotId] = 0;
              slotTimers[slotId] = Duration.zero;
            }
          }
        }
      });
    });
  }

  DateTime parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return DateTime.now();
    }

    try {
      // Handle the format in your API like "2025-03-12 22:30:00"
      if (dateTimeString.contains(' ')) {
        // Split into date and time parts
        List<String> parts = dateTimeString.split(' ');
        String datePart = parts[0];
        String timePart = parts[1];

        // Parse date components
        List<String> dateComponents = datePart.split('-');
        int year = int.parse(dateComponents[0]);
        int month = int.parse(dateComponents[1]);
        int day = int.parse(dateComponents[2]);

        // Parse time components
        List<String> timeComponents = timePart.split(':');
        int hour = int.parse(timeComponents[0]);
        int minute = int.parse(timeComponents[1]);
        int second =
            timeComponents.length > 2 ? int.parse(timeComponents[2]) : 0;

        return DateTime(year, month, day, hour, minute, second);
      } else {
        // Fall back to default parsing if format is different
        return DateTime.parse(dateTimeString);
      }
    } catch (e) {
      print('Error parsing date time: $e');
      return DateTime.now();
    }
  }

  void selectSlot(String slotId) {
    setState(() {
      selectedSlotId = (selectedSlotId == slotId) ? null : slotId;
    });
  }

  final List<String> imageUrls = [
    'https://res.cloudinary.com/dwdatqojd/image/upload/v1738778166/060c9fri-removebg-preview_lqj6eb.png',
    'https://res.cloudinary.com/dwdatqojd/image/upload/v1738776910/wmremove-transformed-removebg-preview_sdjfbl.png',
    'https://res.cloudinary.com/dwdatqojd/image/upload/v1738778166/060c9fri-removebg-preview_lqj6eb.png',
  ];


  void showSlotDetails(BuildContext context, Map<String, dynamic> slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        String slotNumber = slot['slotNumber']?.toString() ?? 'Unknown';
        String slotId = slot['id']?.toString() ?? 'Unknown';
        String type = slot['type']?.toString() ?? 'Unknown';
        bool isAvailable = slot['availability'] == true;
        bool isHeld = slot['hold'] == true;

        print('Slot Details: $slotId');

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Slot Details:$slotNumber',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text('Type: $type'),
              SizedBox(height: 20),
              if (isHeld)
                Column(
                  children: [
                    Image.network(
                      'https://res.cloudinary.com/dwdatqojd/image/upload/v1739980797/hold_lifmpt.png',
                      width: 400,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Slot is held. Booking in progress',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ],
                ),
              if (!isAvailable)
                Center(
                  child: Column(
                    children: [
                      Image.network(
                        'https://res.cloudinary.com/dwdatqojd/image/upload/v1739980793/una_dsjrfj.png',
                        width: 400,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This slot is currently unavailable ',
                        style: TextStyle(
                            color: const Color.fromARGB(255, 15, 148, 181),
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 40),
              if (isAvailable && !isHeld)
                ElevatedButton(
                  onPressed: ()  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateTimePickerPage(slotId: slotId, slotType: type, slotNumber: slotNumber),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    elevation: MaterialStateProperty.all(5),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  child: Text('Book Slot'),
                ),
              if (!isAvailable || isHeld)
                ElevatedButton(
                  onPressed: null,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        isHeld ? Colors.orange : Colors.grey),
                    foregroundColor: MaterialStateProperty.all<Color>(isHeld
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : const Color.fromARGB(255, 255, 255, 255)),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 60, vertical: 25),
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    elevation: MaterialStateProperty.all(0),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  child: Text(isHeld ? 'Slot is Hold' : 'Slot Unavailable'),
                ),
            ],
          ),
        );
      },
    );
  }

  /*Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ??
        'defaultUserId'; // Replace 'defaultUserId' with a default value if needed
  }*/

  Widget getSlotIcon(String? type, Map<String, dynamic> slot) {
    switch (type?.toLowerCase()) {
      case 'car':
        return Icon(Icons.drive_eta, size: 18, color: Colors.white);
      case 'bike':
        return Icon(Icons.two_wheeler, size: 18, color: Colors.white);
      case 'bus':
        return Icon(Icons.directions_bus, size: 18, color: Colors.white);
      default:
        return Text(
          slot.containsKey('slotNumber') ? slot['slotNumber'].toString() : '',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Trigger the refresh action
              refreshData();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Error Image and Text
          if (showErrorImage)
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'https://res.cloudinary.com/dwdatqojd/image/upload/v1738778166/060c9fri-removebg-preview_lqj6eb.png',
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error, size: 100, color: Colors.red);
                    },
                  ),
                  Text(
                    'Please select a parking area first',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            ),
          // Parking Slot Layout
          Expanded(
            child: mockSlots.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        dragOffset = Offset(
                          dragOffset.dx +
                              details.localPosition.dx * dragSensitivity,
                          dragOffset.dy +
                              details.localPosition.dy * dragSensitivity,
                        );

                        // Implementing wraparound or infinite scroll horizontally
                        if (dragOffset.dx > 3000) {
                          dragOffset =
                              Offset(dragOffset.dx - 3000, dragOffset.dy);
                        } else if (dragOffset.dx < 0) {
                          dragOffset =
                              Offset(dragOffset.dx + 3000, dragOffset.dy);
                        }

                        // Implementing wraparound or infinite scroll vertically
                        if (dragOffset.dy > 3000) {
                          dragOffset =
                              Offset(dragOffset.dx, dragOffset.dy - 3000);
                        } else if (dragOffset.dy < 0) {
                          dragOffset =
                              Offset(dragOffset.dx, dragOffset.dy + 3000);
                        }
                      });
                    },
                    child: InteractiveViewer(
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 0.8,
                      maxScale: 4.0,
                      onInteractionUpdate: (details) {
                        if (details.scale <= 0.3) {
                          setState(() {
                            dragOffset = Offset(0.0, 0.0);
                          });
                        }
                      },
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SizedBox(
                            width: 800,
                            height: 1500,
                            child: Stack(children: [
                              for (int i = 0; i < mockSlots.length; i++)
                                Positioned(
                                  left: 20,
                                  top: i == 0 ? (80.0 + labelSpacing) * i : (160.0 + labelSpacing) * i,
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ...mockSlots.map((slot) {
                                String slotId = slot['id']?.toString() ?? 'unknown';
                                bool isSelected = selectedSlotId == slotId;

                                // Safely parse x and y values
                                double xPos = double.tryParse(slot['x']?.toString() ?? '0') ?? 0.0;
                                double yPos = double.tryParse(slot['y']?.toString() ?? '0') ?? 0.0;

                                return Positioned(
                                  left: xPos + dragOffset.dx,
                                  top: yPos + dragOffset.dy,
                                  child: SlotWidget(
                                    slot: slot,
                                    progress: slotProgress[slotId] ?? 1.0,
                                    isSelected: isSelected,
                                    onSelect: () {
                                      selectSlot(slotId);
                                      showSlotDetails(context, slot);
                                    },
                                    getIcon: getSlotIcon,
                                    timerText: formatRemainingTime(
                                        slotTimers[slotId] ?? Duration.zero),
                                  ),
                                );
                              }).toList(),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          // Legend Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendBox(Colors.blueAccent, "Bike"),
                SizedBox(width: 10),
                _buildLegendBox(Colors.orangeAccent, "Car"),
                SizedBox(width: 10),
                _buildLegendBox(const Color.fromARGB(255, 82, 23, 23), "Bus"),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Function to create the legend boxes
  Widget _buildLegendBox(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class SlotWidget extends StatelessWidget {
  final Map<String, dynamic> slot;
  final double progress;
  final bool isSelected;
  final VoidCallback onSelect;
  final Widget Function(String?, Map<String, dynamic>) getIcon;
  final String timerText;

  const SlotWidget({
    Key? key,
    required this.slot,
    required this.progress,
    required this.isSelected,
    required this.onSelect,
    required this.getIcon,
    required this.timerText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    bool isAvailable = slot['availability'] == true;
    bool isHeld = slot['hold'] == true;


    Color borderColor = isSelected
        ? Colors.green
        : slot['type'] == 'bike'
        ? Colors.blue
        : slot['type'] == 'car'
        ? Colors.orange
        : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Only show progress bar if slot is not available and not on hold
        if (!isAvailable && !isHeld && progress > 0)
          Container(
            width: double.tryParse(slot['width']?.toString() ?? '20') ?? 20.0,
            height: 6,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: onSelect,
          child: Container(
            width: double.tryParse(slot['width']?.toString() ?? '20') ?? 20.0,
            height: double.tryParse(slot['height']?.toString() ?? '20') ?? 20.0,
            decoration: BoxDecoration(
              color: isHeld ? Colors.yellow : (isAvailable ? Colors.green : Colors.red),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: slot['type'] != null
                      ? getIcon(slot['type'], slot)
                      : Text(
                    slot.containsKey('slotNumber')
                        ? slot['slotNumber'].toString()
                        : '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Only show timer text if slot is not available and not on hold
                if (!isAvailable && !isHeld && timerText.isNotEmpty)
                  Positioned(
                    bottom: 1,
                    left: 2,
                    right: 2,
                    child: Text(
                      timerText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Color _parseColor(String colorString, bool isSelected) {
  // Check if the slot is selected
  if (isSelected) {
    return Colors.red; // Return red color if selected
  }

  // Handle custom color string parsing

  // Default color if the string is invalid
  return Colors.grey.shade400;
}

void showSlotDetailsBottomSheet(
    BuildContext context, Map<String, dynamic> slot) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows full-height modal if needed
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SizedBox(
        height: 300,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Fixed Height Popup',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('This popup has a fixed height of 300 pixels.'),
              Spacer(), // Pushes button to the bottom
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the popup
                  },
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
