import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gscanner/doc_scan.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/splash_video.mp4')
      ..initialize()
          .then((_) {
            setState(() {
              _isVideoInitialized = true;
            });
            _controller.play();
            _controller.setLooping(true);
          })
          .catchError((error) {
            setState(() {
              _isVideoInitialized = false;
            });
            print("Error initializing video player: $error");
          });

    Timer(const Duration(seconds: 7), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => DocumentScannerScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isVideoInitialized
            ? SizedBox(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : Image.asset(
                'assets/gbscanner.png',
                height: 180,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
