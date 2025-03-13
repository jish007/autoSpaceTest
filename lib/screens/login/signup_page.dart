import 'dart:convert';
import 'package:autospaxe/screens/login/vehicle_info_popup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();
  late FocusNode _emailFocusNode;
  late FocusNode _phoneFocusNode;
  late FocusNode _usernameFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;
  late FocusNode _vehicleDetailsFocusNode;

  bool _isLoading = false;

  late Map<String,String> vehicleData;

  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _vehicleDetailsError;
  String? _phoneError;

  final ApiService apiService =
      ApiService(); // Create an instance of ApiService

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    _emailFocusNode = FocusNode();
    _usernameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    _vehicleDetailsFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _vehicleDetailsFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _navigateToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> signupUser() async {
    final username = _usernameController.text.toString();
    final email = _emailController.text.trim().toString();
    final password = _passwordController.text.trim().toString();
    final confirmPassword = _confirmPasswordController.text.trim().toString();
    final vehicleDetails = vehicleController.text.trim();
    final phoneNum = _phoneController.text.trim().toString();

    if (username.isEmpty) {
      setState(() => _usernameError = 'Username is required');
      return;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirm password is required');
      return;
    }
    if (vehicleDetails.isEmpty) {
      setState(() => _vehicleDetailsError = 'Vehicle Details is required');
      return;
    }
    if (phoneNum.isEmpty) {
      setState(() => _phoneError = 'Phone Number is required');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response =
        await apiService.signup(username, email, password, vehicleData, phoneNum);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup successful")),
      );

      // Navigate to another screen after signup (Example: LoginPage)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: ${response.body}")),
      );
    }
  }

  void _validateSignUp() {
    setState(() {
      _emailError = _validateEmail(_emailController.text.toString());
      _phoneError = _validatePhone(_phoneController.text.toString());
      _usernameError = _usernameController.text.isEmpty ? 'Please enter a username' : null;
      _vehicleDetailsError = vehicleController.text.isEmpty ? 'Please enter vehicle details' : null;
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError =
          _confirmPasswordController.text != _passwordController.text
              ? 'Passwords do not match'
              : null;
    });

    if (_emailError == null &&
        _usernameError == null &&
        _passwordError == null &&
        _vehicleDetailsError == null &&
        _confirmPasswordError == null &&
        _phoneError == null) {
      signupUser();
    }
  }

  String? _validateEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isEmpty) {
      return 'Please enter your email';
    } else if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String phoneNum) {
    final phoneRegex =
    RegExp(r'^[6-9]\d{9}$');
    if (phoneNum.isEmpty) {
      return 'Please enter your phone number';
    } else if (!phoneRegex.hasMatch(phoneNum)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (password.isEmpty) {
      return 'Please enter a password';
    } else if (!passwordRegex.hasMatch(password)) {
      return 'Password must be at least 8 characters long, with at least one uppercase letter, one number, and one special character';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SlideTransition(
            position: _animation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(70),
                    topRight: Radius.circular(70),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Getting Started',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Image.network(
                        'https://res.cloudinary.com/dwdatqojd/image/upload/v1738778483/knnx_ioyjrq.png',
                        // Replace with your network image URL
                        width: 80, // Adjust size of logo
                        height: 80,
                        fit:
                            BoxFit.contain, // Adjust the fit property as needed
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Email',
                        icon: Icons.email,
                        errorText: _emailError,
                        textInputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedTextField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        label: 'Username',
                        icon: Icons.person,
                        errorText: _usernameError,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedTextField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        errorText: _phoneError,
                        textInputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        errorText: _passwordError,
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedTextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        errorText: _confirmPasswordError,
                      ),
                      const SizedBox(height: 20),
                    _buildAnimatedTextField(
                      controller: vehicleController,
                      focusNode: FocusNode(),
                      label: "Add vehicle details",
                      icon: Icons.directions_car,
                      onAddVehicle: () {
                        showDialog(
                          context: context,
                          builder: (context) => VehicleInfoPopup(
                            onSave: (bool isFourWheeler, Map<String, String> vehicleDetails) {
                              if (vehicleDetails.isNotEmpty) {
                                // Example: Update the text field with vehicle details
                                vehicleController.text = vehicleDetails['vehicleName'] ?? 'Vehicle Added';
                                setState(() {
                                  vehicleData = vehicleDetails;
                                });

                                print(vehicleData);

                                // You can also store vehicleDetails in another variable if needed
                              } else {
                                print("Vehicle save failed.");
                              }
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _validateSignUp,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 150, vertical: 27),
                        ),
                        child: const Text('Sign up'),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _navigateToLoginPage,
                        child: const Text(
                          'You already have an account? Login',
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? errorText,
    TextInputType? textInputType,
    VoidCallback? onAddVehicle, // Callback function for Add Vehicle button
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Focus(
          onFocusChange: (hasFocus) {
            setState(() {});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                keyboardType: textInputType,
                controller: controller,
                obscureText: isPassword,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.black),
                readOnly: label == "Add vehicle details", // Make it read-only only for Add vehicle details
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: label,
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.8)),
                  prefixIcon: AnimatedScale(
                    scale: focusNode.hasFocus || controller.text.isNotEmpty ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      color: focusNode.hasFocus || controller.text.isNotEmpty
                          ? Colors.blue
                          : Colors.black.withOpacity(0.8),
                    ),
                  ),
                  suffixIcon: label == "Add vehicle details" // Show "+" button only for Add Vehicle Details
                      ? IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: onAddVehicle, // Open popup on click
                  )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorText,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

}
