import 'dart:convert';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://spare-felita-pn87-9ad509ad.koyeb.app';

  Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    Map<String, String> loginData = {
      "email": email,
      "password": password,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(loginData),
    );

    return response;
  }

  Future<http.Response> signup(String username, String email, String password,
      Map<String, String> vehicleData, String phoneNum) async {
    final url = Uri.parse('$baseUrl/profiles/save');
    Map<String, String> signupData = {
      "userName": username,
      "userEmailId": email,
      "password": password,
      "phoneNum": phoneNum,
    };
    signupData.addAll(vehicleData);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(signupData),
    );

    return response;
  }

  Future<http.Response> bookSlot(
      String vehicleNumber,
      String bookingDate,
      String endtime,
      String slotId,
      String paidAmount,
      String bookingTime,
      String bookingSource,
      int durationOfAllocation) async {
    final url = Uri.parse('$baseUrl/user-app/slot-booking');
    Map<String, dynamic> bookingData = {
      "vehicleNumber": vehicleNumber,
      "bookingDate": bookingDate,
      "endtime": endtime,
      "slotId": slotId,
      "paidAmount": paidAmount,
      "bookingTime": bookingTime,
      "bookingSource": bookingSource,
      "durationOfAllocation": durationOfAllocation,
    };
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(bookingData),
    );

    return response;
  }

  Future<http.Response> addOnSlot(
      String vehicleNum, String duration, String fare) async {
    final url = Uri.parse('$baseUrl/user-app/recharge');
    Map<String, dynamic> bookingData = {
      "duration": duration,
      "vehicleNumber": vehicleNum,
      "fare": fare,
    };
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(bookingData),
    );

    return response;
  }

  Future<http.Response> logOutUser(String emailId) async {
    var client = BrowserClient();
    final response = await client.get(Uri.parse(
        "$baseUrl/profiles/logout?emailId=$emailId"));
    return response;
  }

  Future<http.Response> addVehicle(String vehicleNumber, String brand,
      String model, String color, int userId) async {
    final url = Uri.parse('$baseUrl/vehicles');
    Map<String, dynamic> vehicleData = {
      "vehicleNumber": vehicleNumber,
      "brand": brand,
      "model": model,
      "color": color,
      "user": {"id": userId}
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(vehicleData),
    );

    return response;
  }

  Future<List<Map<String, dynamic>>> getNearbyParkingSpots() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/property-image/get-all-property'));

      if (response.statusCode == 200) {
        // Check if the response body is valid JSON
        try {
          List<dynamic> data = jsonDecode(response.body);
          return data
              .map((spot) => {
                    'name': spot['propertyName'],
                    'description': spot['propertyDesc'],
                    'imageUrl': spot['image2'],
                    'location': spot['propertyLocation'],
                    'ratePerHour': spot['ratePerHour'],
                    'adminMailId': spot['adminMailId'],
                  })
              .toList();
        } catch (e) {
          throw Exception("Invalid JSON response: $e");
        }
      } else {
        // Handle non-200 status codes
        throw Exception("Failed to load parking spots: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetchibacng parking spots: $e");
      throw Exception("Network error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getVehiclesByUserId(int userId) async {
    final url = Uri.parse('$baseUrl/vehicles/user/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((vehicle) => {
                'vehicleNumber': vehicle['vehicleNumber'],
                'brand': vehicle['brand'],
                'model': vehicle['model'],
                'color': vehicle['color'],
              })
          .toList();
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<Map<String, dynamic>> fetchParkingSpotById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/parking-spots/$id'));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'id': data['id'],
          'name': data['name'],
          'description': data['description'],
          'imageUrl': data['imageUrl'],
          'ratePerHour': data['ratePerHour'],
        };
      } else {
        throw Exception("Failed to load parking spot: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching parking spot: $e");
      throw Exception("Network error: $e");
    }
  }
}
