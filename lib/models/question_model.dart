// question_model.dart

class Question {
  final int id;
  final String text;
  final List<String> options;
  final String answer;
  String userAnswer;
  final int loveBar;

  Question(
    this.id,
    this.text,
    this.options,
    this.answer, {
    this.loveBar = 0,
    this.userAnswer = '',
  });
}
