enum LetterState { absent, present, correct }

class LetterFeedback {
  const LetterFeedback(this.letter, this.state);
  final String letter;
  final LetterState state;
}
