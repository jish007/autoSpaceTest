import 'package:autospaxe/providers/ParkingProvider.dart';
import 'package:autospaxe/providers/user_provider.dart';
import 'package:autospaxe/screens/Home/home_screen.dart';
import 'package:autospaxe/screens/login/login_page.dart';
import 'package:autospaxe/screens/login/signup_page.dart';
import 'package:autospaxe/screens/login/splash_screen.dart';
import 'package:autospaxe/screens/main_screen.dart';
import 'package:autospaxe/screens/maps/date_time_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ParkingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage()
    );
  }
}
