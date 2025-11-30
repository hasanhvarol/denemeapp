import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Sadece Firebase'i garantili başlatıyoruz
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Bildirim delegesini Flutter'a bırakıyoruz (Plugin kendi hallediyor)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}