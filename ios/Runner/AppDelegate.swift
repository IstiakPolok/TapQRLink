import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.tapqrlink/subscriptions",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "showManageSubscriptions" {
          if #available(iOS 15.0, *) {
            Task { @MainActor in
              guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
                $0.activationState == .foregroundActive
              }) as? UIWindowScene else {
                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                result(true)
                return
              }
              do {
                try await AppStore.showManageSubscriptions(in: windowScene)
                result(true)
              } catch {
                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                  UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                result(true)
              }
            }
          } else {
            if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
              UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            result(true)
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
