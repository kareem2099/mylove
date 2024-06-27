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
  Color _buttonColor = Colors.pinkAccent;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  bool _isAnswered = false; // Flag to track if the question is answered

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    if (_isAnswered) return; // Prevent multiple answers

    widget.questions[_currentQuestionIndex].userAnswer = selectedOption;
    bool isCorrect =
        selectedOption == widget.questions[_currentQuestionIndex].answer;

    setState(() {
      _buttonColor = isCorrect ? Colors.deepPurpleAccent : Colors.pinkAccent;
      _isAnswered = true; // Mark the question as answered
    });

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
                  Navigator.of(context).pop();
                  if (_currentQuestionIndex < widget.questions.length - 1) {
                    setState(() {
                      _currentQuestionIndex++;
                      _buttonColor = Colors.pinkAccent;
                      _isAnswered = false; // Reset for the next question
                    });} else {
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
    _updateProgressAnimation(widget.questions[_currentQuestionIndex].loveBar);
  }

  int calculateScore() {
    int score = 0;
    for (Question question in widget.questions) {
      if (question.userAnswer == question.answer) {
        score += question.loveBar;
      }
    }
    return score;
  }

  // Widget to build each option button
  Widget _buildOptionButton(String option, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnimatedContainer(
        key: ValueKey<String>(option), // Use a key for optimization
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
            padding:
            const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            elevation: 5.0,
          ),
          onPressed: _isAnswered ? null : () => _handleAnswer(option), // Disable if answered
          child: SizedBox(
            width: double.infinity,
            child: AnimatedTextKit(
              animatedTexts: [
                for (int i = 0; i < 30; i++)
                  ColorizeAnimatedText(
                    option,
                    textStyle: const TextStyle(fontSize: 18),
                    colors: [
                      Colors.purple,
                      Colors.blue,
                      Colors.yellow,
                      Colors.red,
                    ],
                    textAlign: TextAlign.center,
                  ),
              ],),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Question currentQuestion = widget.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Quiz'),
        backgroundColor: Colors.pink,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/loveu.gif'),
                const SizedBox(width: 24),
                SizedBox(
                  width: double.infinity, // Make thetext take the available width
                  child: AnimatedTextKit(
                    animatedTexts: [
                      for (int i = 0; i < 30; i++)
                        ColorizeAnimatedText(
                          currentQuestion.text,
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          colors: [ // Add your desired colors here
                            Colors.purple,
                            Colors.blue,
                            Colors.yellow,
                            Colors.red,
                          ],
                          textAlign: TextAlign.center,
                        ),
                    ],
                    isRepeatingAnimation: true, // Keep the animation looping

                  ),
                ),
                const SizedBox(height: 32),
                // Build option buttons using the extracted function
                ...currentQuestion.options
                    .asMap()
                    .map((index, option) =>
                    MapEntry(index, _buildOptionButton(option, index)))
                    .values,
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