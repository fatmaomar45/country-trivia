/// Represents the current state of the trivia game.
enum GameState {
  /// Initial state while countries are being fetched and the first
  /// question is being generated.
  loading,

  /// Active gameplay — the flag is displayed and the user can select
  /// an answer.
  playing,

  /// The question has been resolved — either the user guessed correctly
  /// or all attempts were exhausted. The correct answer is revealed.
  revealed,
}
