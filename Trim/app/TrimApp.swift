import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    if FirebaseApp.app() == nil {
        if let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
           let dict = NSDictionary(contentsOf: url),
           let appId = dict["GOOGLE_APP_ID"] as? String,
           !appId.isEmpty,
           appId != "REPLACE_ME" {
            FirebaseApp.configure()
        } else {
            print("Firebase not configured: missing or placeholder GoogleService-Info.plist")
        }
    }
    return true
  }
}

@main
struct TrimApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
