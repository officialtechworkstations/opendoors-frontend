import UIKit
import Flutter
import GoogleMaps
// import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  // private static var isFirebaseConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBy-e28ndAtWwDlAQPyXUuCgJhwE-P2rqw")

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
  //   GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  //    // Configure Firebase only once
  //   if !AppDelegate.isFirebaseConfigured {
  //     FirebaseApp.configure()
  //     AppDelegate.isFirebaseConfigured = true
  //   }
  //   // FirebaseApp.configure()
  // }
}
