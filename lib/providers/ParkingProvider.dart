import 'package:flutter/foundation.dart';

class ParkingProvider extends ChangeNotifier {
  String _parkingName = '';
  String _parkingDescription = '';
  dynamic _parkingImageUrl = '';
  String _parkingLocation = '';
  String _ratePerHour = '0.0';
  String _adminMailId= '';

  String get parkingName => _parkingName;
  String get parkingDescription => _parkingDescription;
  dynamic get parkingImageUrl => _parkingImageUrl;
  String get parkingLocation => _parkingLocation;
  String get ratePerHour => _ratePerHour;
  String get adminMailId => _adminMailId;

  void setParkingSpot({
    required String name,
    required String description,
    required dynamic imageUrl,
    required String parkingLocation,
    required String ratePerHour,
    required String adminMailId,
  }) {
    _parkingName = name;
    _parkingDescription = description;
    _parkingImageUrl = imageUrl;
    _parkingLocation = parkingLocation;
    _ratePerHour = ratePerHour;
    _adminMailId = adminMailId;
    notifyListeners();
  }
}