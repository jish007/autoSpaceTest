import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../providers/ParkingProvider.dart';
import '../bookings/bookings.dart';

class DetailsScreen extends StatefulWidget {
  final Map<String, dynamic> parkingSpot;

  const DetailsScreen({
    Key? key,
    required this.parkingSpot,
  }) : super(key: key);

  @override
  _TomTomRoutingPageState createState() => _TomTomRoutingPageState();
}

class _TomTomRoutingPageState extends State<DetailsScreen> {
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Parking Details", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image with elevation
            Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.memory(
                  convertToImage(widget.parkingSpot['imageUrl']),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 120),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card with parking details
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Parking Spot Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    DetailRow(icon: Icons.local_parking, label: "Name", value: widget.parkingSpot['name']),
                    DetailRow(icon: Icons.description, label: "Description", value: widget.parkingSpot['description']),
                    DetailRow(icon: Icons.attach_money, label: "Rate per Hour", value: widget.parkingSpot['ratePerHour'].toString()),
                    DetailRow(icon: Icons.email, label: "Admin Email", value: widget.parkingSpot['adminMailId']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Action button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.home),
              label: Text("Back to Home", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Uint8List convertToImage(imageBase64) {
    return Base64Decoder().convert(imageBase64);
  }

  Widget DetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
