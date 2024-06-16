import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../page/auth_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/splashScreen.mp4')
      ..initialize().then((_) {
        _controller!.play();
        _controller!.setLooping(true);
        setState(() {});
      });
    _navigateToHome();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  _navigateToHome() async {

      await Future.delayed(const Duration(seconds: 15), () {});
      if(mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const AuthPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller?.value.isInitialized ?? false
          ? FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      )
          : Container(),
    );
  }
}
