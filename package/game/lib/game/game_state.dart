enum GameState {
  init(-1),
  stopped(-1),

  /// loading ilp layers
  loading(0),
  loadError(1),

  /// game image fade in animate
  animating(2),
  already(3),
  started(4),
  paused(5),
  completed(7),
  failed(8);

  final num value;

  const GameState(this.value);
}
