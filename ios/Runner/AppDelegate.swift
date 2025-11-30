import UIKit
import Flutter
import Firebase
import flutter_local_notifications // 1. Local Notifications paketini import ettik

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. Firebase'i başlatma komutu
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    
    // 3. Local Notifications için gerekli setup. Bu satır eklenmeli.
    FlutterLocalNotificationsPlugin.set       
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}