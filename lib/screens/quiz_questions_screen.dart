import 'package:flutter/material.dart';
import 'package:mylove/models/question_model.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'result_screen.dart';

class QuizQuestionsScreen extends StatefulWidget {
  final List<Question> questions;

  const QuizQuestionsScreen({super.key, required this.questions});

  @override
  State<QuizQuestionsScreen> createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends State<QuizQuestionsScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  Color _buttonColor = Colors.pinkAccent; // Updated button color
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500), // Duration of the animation
      vsync: this,
    );
    _progressAnimation =
        Tween<double>(begin: 0, end: 1).animate(_progressAnimationController)
          ..addListener(() {
            setState(() {});
          });
    _updateProgressAnimation(widget.questions[_currentQuestionIndex].loveBar);
  }

  void _updateProgressAnimation(int loveBarValue) {
    int totalLoveBar = widget.questions.fold<int>(
        0, (previousValue, question) => previousValue + question.loveBar);
    int currentLoveBar = widget.questions
        .sublist(0, _currentQuestionIndex + 1)
        .fold<int>(
            0,
            (previousValue, question) =>
                previousValue +
                (question.userAnswer == question.answer
                    ? question.loveBar
                    : 0));

    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: currentLoveBar / totalLoveBar,
    ).animate(_progressAnimationController)
      ..addListener(() {
        setState(() {});
      });
    _progressAnimationController.forward(from: 0);
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _handleAnswer(String selectedOption) {
    widget.questions[_currentQuestionIndex].userAnswer = selectedOption;
    bool isCorrect =
        selectedOption == widget.questions[_currentQuestionIndex].answer;

    // Change the button color based on correctness
    setState(() {
      _buttonColor = isCorrect ? Colors.deepPurpleAccent : Colors.pinkAccent;
    });

    // Show the result in a dialog
    Future.delayed(const Duration(seconds: 1), () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Image.asset(
              isCorrect ? 'assets/images/happy.gif' : 'assets/images/sad.gif',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Next Question'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  if (_currentQuestionIndex < widget.questions.length - 1) {
                    setState(() {
                      _currentQuestionIndex++;
                      _buttonColor =
                          Colors.pinkAccent; // Reset the button color
                    });
                  } else {
                    // If there are no more questions, navigate to a results screen or show a final message
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultScreen(score: calculateScore()),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    });
    // Update the progress bar with the new value
    _updateProgressAnimation(widget.questions[_currentQuestionIndex].loveBar);
  }

  // Calculate the user's score (you can implement your own scoring logic)
  int calculateScore() {
    int score = 0;
    for (Question question in widget.questions) {
      if (question.userAnswer == question.answer) {
        score += question.loveBar; // Add the loveBar value to the score
      }
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    Question currentQuestion = widget.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Quiz'),
        backgroundColor: Colors.pink, // Consistent theme color
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Use the minimum space
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/loveu.gif'),

                const SizedBox(width: 24), // Spacing between animation and text
                // Romantic question title
                AnimatedTextKit(
                  animatedTexts: [
                    for (int i = 0;
                        i < 30;
                        i++) // Repeat 30 times (adjust as needed)
                      TypewriterAnimatedText(
                        currentQuestion.text,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        speed: const Duration(
                            milliseconds: 200), // Adjust initial speed
                      ),
                  ],
                ),

                const SizedBox(height: 32),
                // Inside your build method, replace the existing options code with the following:
                ...currentQuestion.options
                    .asMap()
                    .map((index, option) => MapEntry(
                          index,
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: _currentQuestionIndex == index
                                    ? Colors.deepPurpleAccent
                                    : _buttonColor,
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 20),
                                  elevation: 5.0,
                                ),
                                onPressed: () => _handleAnswer(option),
                                child: SizedBox(
                                  width: double
                                      .infinity, // Ensures the text is centered
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      for (int i = 0; i < 30; i++)
                                        ColorizeAnimatedText(
                                          option,
                                          textStyle:
                                              const TextStyle(fontSize: 18),
                                          colors: [
                                            Colors.purple,
                                            Colors.blue,
                                            Colors.yellow,
                                            Colors.red,
                                          ],
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))
                    .values
                    ,

                // Use the animated progress value
                LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
