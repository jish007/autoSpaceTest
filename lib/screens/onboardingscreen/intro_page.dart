import 'dart:ui';
import 'package:autospaxe/screens/login/signup_page.dart';
import 'package:autospaxe/screens/onboardingscreen/screen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../login/login_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animationController;
  late Animation<double> _screenFadeAnimation;
  late Animation<double> _contentFadeAnimation;
  bool _videoStoppedAt9_5 = false; // Track if video stopped at 9.5 sec

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset("lib/assets/gif/assets_intro_video.webm")
      ..initialize().then((_) {
        setState(() {});
        _controller.setPlaybackSpeed(.87);
        _controller.play();
      });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _screenFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)),
    );

    _animationController.forward();

    // Listen for video progress to stop at 9.5 sec
    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= const Duration(milliseconds: 10000) &&
          !_videoStoppedAt9_5) {
        _controller.pause(); // Stop at 9.5 sec
        _videoStoppedAt9_5 = true; // Prevent multiple triggers
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _screenFadeAnimation,
        child: Stack(
          children: [
            // Background Video
            Positioned.fill(
              child: _controller.value.isInitialized
                  ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
                  : Container(color: Colors.black),
            ),

            // Transparent Overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.21),
              ),
            ),

            // Bottom Gradient
            Positioned(
              bottom: 250,
              left: 0,
              right: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                      Colors.black.withOpacity(0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // "AUTO SPACE" Title with modern gradient and glow effect
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(_contentFadeAnimation),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.white10.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      "AUTO SPAXE",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.blueAccent.withOpacity(0.8),
                            offset: const Offset(0, 4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Subtitle: "Simplify Your Parking Experience"
            Positioned(
              top: 195,
              left: 30,
              right: 30,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_contentFadeAnimation),
                  child: Text(
                    "Simplify Your Parking Experience",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      letterSpacing: 1.8,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Get Started Button
            Positioned(
              bottom: 130,
              left: 30,
              right: 30,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _controller.play(); // Continue video from 9.5 sec
                        Future.delayed(const Duration(seconds: 3), () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) =>   SignUpPage()),
                          );
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 3,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.001),
                                  Colors.black.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Text(
                              "Get Started",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: GestureDetector(
                        onTap: () {
                          _controller.play(); // Continue video from 9.5 sec
                          Future.delayed(const Duration(seconds: 3), () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          });
                        },
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}