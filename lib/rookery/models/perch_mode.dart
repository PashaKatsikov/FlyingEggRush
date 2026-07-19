/// The routing state persisted between launches.
///
/// - [fresh]: first launch — attribution + config must run.
/// - [web]:   previous launch reached the WebView; return there.
/// - [game]:  previous launch committed to the native game; may still
///            re-convert to `web` on a later launch (see `RoostPilot`).
enum PerchMode { fresh, web, game }

extension PerchModeCodec on PerchMode {
  String get storageKey => switch (this) {
        PerchMode.fresh => 'fresh',
        PerchMode.web => 'web',
        PerchMode.game => 'game',
      };

  static PerchMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
        return PerchMode.web;
      case 'game':
        return PerchMode.game;
      default:
        return PerchMode.fresh;
    }
  }
}
