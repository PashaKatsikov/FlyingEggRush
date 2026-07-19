import Flutter
import UIKit

/// Extracts a URL from a cold-start push notification tap.
///
/// `FirebaseMessaging.getInitialMessage()` returns nil when the app was
/// killed and re-launched by tapping a push (flutterfire#8896). iOS delivers
/// the tap through `scene(_:willConnectTo:options:)` — we capture the URL
/// here and write it to UserDefaults; Dart reads it via SharedPreferences.
///
/// The key MUST match `NativeLandingBridge._key` on the Dart side (with the
/// mandatory `flutter.` prefix that maps NSUserDefaults ↔ SharedPreferences).
class SceneDelegate: FlutterSceneDelegate {

  private static let tapUrlKey = "flutter.feg_launch_route"
  private static let urlKeys = ["url", "link", "target", "deeplink", "deep_link"]

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let response = connectionOptions.notificationResponse {
      let info = response.notification.request.content.userInfo
      if let url = SceneDelegate.extractUrl(from: info) {
        UserDefaults.standard.set(url, forKey: SceneDelegate.tapUrlKey)
        #if DEBUG
        NSLog("[FEG.scene] captured cold-start url=%@", url)
        #endif
      }
    }
  }

  static func extractUrl(from userInfo: [AnyHashable: Any]) -> String? {
    if let hit = firstUrl(in: userInfo) { return hit }
    if let nested = userInfo["data"] as? [AnyHashable: Any],
       let hit = firstUrl(in: nested) { return hit }
    if let nested = userInfo["payload"] as? [AnyHashable: Any],
       let hit = firstUrl(in: nested) { return hit }
    if let aps = userInfo["aps"] as? [AnyHashable: Any],
       let hit = firstUrl(in: aps) { return hit }
    return nil
  }

  private static func firstUrl(in dict: [AnyHashable: Any]) -> String? {
    for k in urlKeys {
      if let s = dict[k] as? String, !s.isEmpty {
        return s
      }
    }
    return nil
  }
}
