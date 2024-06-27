import 'dart:async';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
// import 'package:path/path.dart' as path;
import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:audioplayers/audioPlayers.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State <CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late ScreenshotController _screenshotController;
  late CameraController _cameraController;
  late Future<void> _initializeCameraControllerFuture;
  late Stopwatch _stopwatch;
  String _recordingTime = '00:00';
  // late AudioPlayer _audioPlayer;
  // final List<String> audio = [
  //   'audios/camer.mp3',
  //   'audios/vedio.mp3',
  //   'audios/camera.wav',
  //   'audios/vedio.wav',
  //   // Add more audio here
  // ];

  @override
  void initState() {
    super.initState();
    // _audioPlayer = AudioPlayer();
    _screenshotController = ScreenshotController();
    _initializeCameraControllerFuture = _initializeCamera();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final permissionStatus = await Permission.camera.request();
    if (permissionStatus == PermissionStatus.granted) {
      _showCameraPermissionDeniedMessage();
    }
  }

  Future<void> _initializeCamera() async {
    final permissionStatus = await Permission.camera.request();
    if (permissionStatus == PermissionStatus.granted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;
        _cameraController = CameraController(
          firstCamera,
          ResolutionPreset.high,
        );
        return _cameraController.initialize(); // This will set the future
      } else {
        _showNoCameraAvailableMessage();
      }
    } else {
      _showCameraPermissionDeniedMessage();
    }
    return Future.error('Camera initialization failed');
  }

  void _showCameraPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Access to the camera was denied. Please enable it in your settings to use this feature.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showNoCameraAvailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No camera is available on this device.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCameraNotInitializedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The camera could not be initialized.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showTakePictureErrorMessage(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred while taking the picture: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSaveImageErrorMessage(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred while saving the image: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showImageSavedMessage(savedImagePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Image has been saved successfully at the following location: $savedImagePath'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showStartRecordingErrorMessage(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text('An error occurred while starting the video recording: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showStopRecordingErrorMessage(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text('An error occurred while stopping the video recording: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSaveVideoErrorMessage(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred while saving the video: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showVideoSavedMessage(savedVideoPath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Video has been saved successfully at the following location: $savedVideoPath'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateRecordingTime() {
    Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!_stopwatch.isRunning) {
        t.cancel();
      }
      final duration = _stopwatch.elapsed;
      setState(() {
        _recordingTime =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
      });
    });
  }

  Future<void> _takePicture() async {
    if (!_cameraController.value.isInitialized) {
      _showCameraNotInitializedMessage();
      return;
    }
    try {
      // await _audioPlayer.play(audio[0]); // Play the camera sound
      final XFile photo = await _cameraController.takePicture();
      _saveImage(photo.path);
    } catch (e) {
      _showTakePictureErrorMessage(e);
    }
  }

  Future<void> _saveImage(String imagePath) async {
    try {
      final result = await ImageGallerySaver.saveFile(imagePath);
      _showImageSavedMessage(result['filePath'] as String? ?? 'Unknown');
    } catch (e) {
      _showSaveImageErrorMessage(e);
    }
  }

  Future<void> _startRecording() async {
    if (!_cameraController.value.isInitialized) {
      _showCameraNotInitializedMessage();
      return;
    }
    try {
      // await _audioPlayer.play(audio[1]); // Play the camera sound
      await _cameraController.startVideoRecording();
      _stopwatch = Stopwatch()..start();
      _updateRecordingTime();
    } catch (e) {
      _showStartRecordingErrorMessage(e);
    }
  }

  Future<void> _stopRecording() async {
    if (!_cameraController.value.isInitialized) {
      _showCameraNotInitializedMessage();
      return;
    }
    try {
      XFile video = await _cameraController.stopVideoRecording();
      _stopwatch.stop();
      _saveVideo(video.path);
    } catch (e) {
      _showStopRecordingErrorMessage(e);
    }
  }

  // Future<void> _playSound(String soundPath) async {
  //   try {
  //     await _audioPlayer.play(Source.asset(soundPath));
  //   } catch (e) {
  //     // Handle error here
  //   }
  // }

  Future<void> _saveVideo(String videoPath) async {
    try {
      final result = await ImageGallerySaver.saveFile(videoPath);
      _showVideoSavedMessage(result['filePath'] as String? ?? 'Unknown');
    } catch (e) {
      _showSaveVideoErrorMessage(e);
    }
  }

  Future<void> _toggleFlash() async {
    if (!_cameraController.value.isInitialized) {
      _showCameraNotInitializedMessage();
      return;
    }
    try {
      if (_cameraController.value.flashMode == FlashMode.off) {
        await _cameraController.setFlashMode(FlashMode.torch);
      } else {
        await _cameraController.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      // Handle any errors here
    }
  }

  // Add methods to show messages to the user here...

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeCameraControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Screenshot(
            controller: _screenshotController,
            child: Scaffold(
              appBar: AppBar(title: const Text('Camera UI')),
              body: Stack(
                children: [
                  CameraPreview(_cameraController),
                  Positioned(
                    top: 16.0,
                    right: 16.0,
                    child: Text(
                      _recordingTime,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _toggleFlash,
                    child: const Icon(Icons.flash_on),
                  ),
                  GestureDetector(
                    onLongPress: _startRecording,
                    onLongPressEnd: (details) => _stopRecording(),
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      child: const Icon(Icons.camera),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    if (_cameraController.value.isInitialized) {
      _cameraController.dispose();
    }

    super.dispose();
  }
}