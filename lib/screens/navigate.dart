import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mylove/screens/quiz_screen.dart';
import 'package:mylove/screens/upload_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State <MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Play the audio when the widget is built
    audioPlayer.play(AssetSource('video/songSplashScreen.mp3'));
  }

  @override
  void dispose() {
    // Stop the audio when the widget is disposed
    audioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Love App'),
        backgroundColor: Colors.pink[300], // Romantic color for the AppBar
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/images/first.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300], // Romantic color for the button
                  ),
                  child: const Text('Go to Quiz Screen'),
                ),
                const SizedBox(height: 20), // Add space between the buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UploadScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300], // Romantic color for the button
                  ),
                  child: const Text('Go to Memory Screen'),
                ),
                const SizedBox(height: 20), // Add space between the buttons
                ElevatedButton(
                  onPressed: () {
                    // Implement navigation to Future Plan screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300], // Romantic color for the button
                  ),
                  child: const Text('Future Plan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
