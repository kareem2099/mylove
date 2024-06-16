import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final int score;

  const ResultScreen({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String message;
    String gifAsset;

    if (score == 100) {
      message = 'Congratulations! Our love story is perfect!';
      gifAsset = 'assets/images/happy.gif';
    } else if (score >= 80) {
      message = 'Great job! Our love shines brightly!';
      gifAsset = 'assets/images/loveu.gif';
    } else if (score >= 50) {
      message = 'Not bad! Our love journey continues!';
      gifAsset = 'assets/images/neutral.gif';
    } else {
      message = 'Better luck next time! Our love is still growing.';
      gifAsset = 'assets/images/sad.gif';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.asset(
              gifAsset,
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to the main screen
              },
              child: const Text('Lets Relive Our Love '),
            ),
          ],
        ),
      ),
    );
  }
}
