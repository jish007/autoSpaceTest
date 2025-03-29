import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userEmail = '';


  String get userEmail => _userEmail;

  void setUserProvider({required String userEmail}){
    _userEmail = userEmail;
    notifyListeners();
  }
}