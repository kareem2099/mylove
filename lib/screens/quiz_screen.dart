import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mylove/bloc/quiz_event.dart';
import 'package:mylove/bloc/quiz_state.dart';
import 'package:mylove/bloc/quiz_bloc.dart';

import 'quiz_questions_screen.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuizBloc()..add(LoadQuiz()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Our Love journey Quiz'),
        ),
        body: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            if (state is QuizInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is QuizLoaded) {
              return Center(
                // Center the content vertically and horizontally
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Use the minimum space
                  children: [
                    Text(
                      'Questions: ${state.questions.length}', // Display the number of questions
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                        height: 20), // Spacing between text and button
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the quiz questions screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                QuizQuestionsScreen(questions: state.questions),
                          ),
                        );
                      },
                      child: const Text('Discover Our Love'),
                    ),
                  ],
                ),
              );
            }
            return const Center(
                child: Text('a7a why u bulling me like bulling ball'));
          },
        ),
      ),
    );
  }
}
