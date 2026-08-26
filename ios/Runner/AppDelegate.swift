import Flutter
import UIKit
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDg3ZMTizoSwd52bmeUzc1QdE_mCWlO2Lk")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // `fastway/native` — small platform channel for native housekeeping Flutter
    // can't do itself.
    //
    // `dismissPresented` works around telr_mobile_payment_sdk 4.4.0: its iOS
    // `payWithApplePay` never dismisses the view controller the native SDK
    // presented (every other method in that plugin does), so after a successful
    // Apple Pay charge the sheet is stranded on screen with a dead close button
    // and the app has to be force-quit. See lib/core/platform/native_sheet.dart.
    guard let messenger = engineBridge.pluginRegistry
      .registrar(forPlugin: "FastwayNative")?.messenger() else { return }

    let channel = FlutterMethodChannel(name: "fastway/native", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "dismissPresented" else {
        result(FlutterMethodNotImplemented)
        return
      }

      DispatchQueue.main.async {
        let root = UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .flatMap { $0.windows }
          .first { $0.isKeyWindow }?
          .rootViewController

        // Only dismiss when something is actually presented above Flutter, so
        // this can be called unconditionally after any Apple Pay attempt.
        if root?.presentedViewController != nil {
          root?.dismiss(animated: true) { result(true) }
        } else {
          result(false)
        }
      }
    }
  }
}
