import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mylove/models/question_model.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc() : super(QuizInitial()) {
    on<LoadQuiz>(_onLoadQuiz);
  }

  Future<void> _onLoadQuiz(LoadQuiz event, Emitter<QuizState> emit) async {
    try {
      final List<Question> loadedQuestions = await loadQuestions();
      emit(QuizLoaded(loadedQuestions));
    } catch (e) {
      // Emit an error state if an exception occurs
      emit(QuizError('Failed to load questions: $e'));
    }
  }

  Future<List<Question>> loadQuestions() async {
    final jsonString =
        await rootBundle.loadString('assets/json/questions.json');
    final jsonMap = json.decode(jsonString);
    final List<dynamic> questionList = jsonMap['questions'];
    return questionList.map((jsonQuestion) {
      return Question(
        jsonQuestion['id'],
        jsonQuestion['question'],
        List<String>.from(jsonQuestion['options']),
        jsonQuestion['answer'],
        loveBar: int.parse(jsonQuestion['loveBar']),
      );
    }).toList();
  }
}
