import 'package:autospaxe/screens/onboardingscreen/intro_page.dart';
import 'package:flutter/material.dart';

import '../login/onboarding_screen.dart';

class ImageSlider extends StatefulWidget {
  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> images = [
      {
        'path':
            'https://res.cloudinary.com/dwdatqojd/image/upload/v1738830090/omx1_yqlyjd.png',
        'heading1': 'Welcome to AutoSpaXe',
        'description':
            'Simplify your parking experience with hassle-free booking, real-time slot updates, and secure access - all from your fingertips ',
        'dotColor': Color.fromARGB(255, 0, 0, 0),
        'backgroundColor': Color.fromARGB(255, 56, 55, 55),
      },
      {
        'path':
            'https://res.cloudinary.com/dwdatqojd/image/upload/v1738830713/Img_car2_n3apej.png',
        'heading1': 'Easy Slot Booking',
        'description':
            'Quickly find and reserve parking spaces near you with just a few taps. No more last-minute stress',
        'dotColor': Color.fromARGB(255, 255, 0, 0),
        'backgroundColor': Color.fromARGB(255, 212, 81, 29),
      },
      {
        'path':
            'https://res.cloudinary.com/dwdatqojd/image/upload/v1738830939/Img_car3_rkbnay.png',
        'heading1': 'Real-Time Slot Monitoring',
        'description':
            'Stay informed with live updates on slot availability, ensuring you know exactly where to park.',
        'dotColor': Color.fromARGB(255, 250, 89, 36),
        'backgroundColor': Color.fromARGB(255, 239, 133, 49),
      },
      {
        'path':
            'https://res.cloudinary.com/dwdatqojd/image/upload/v1738831016/Img_car4_det2ck.png',
        'heading1': 'Get Started Today!',
        'description': 'Sign up now and experience the smartest way to park.',
        'dotColor': Color.fromARGB(255, 34, 194, 253),
        'backgroundColor': Color.fromARGB(255, 98, 180, 250),
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: BouncingScrollPhysics(),
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                color: images[index]['backgroundColor'],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        images[index]['heading1']!,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height *
                          0.57, // Reduced height
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(images[index]['path']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          text: images[index]['description']!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? images[index]['dotColor']
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _controller.jumpToPage(images.length - 1);
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < images.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    } else {
                      // Navigate to another screen or handle last page action
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                IntroPage()), // Replace with your screen
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: Size(100, 50),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
