import SwiftUI
import FirebaseCore

enum FirebaseBootstrap {
    static private(set) var isConfigured: Bool = false
    
    static func configureIfPossible() {
        if FirebaseApp.app() != nil {
            isConfigured = true
            return
        }
        
        guard FirebaseOptions.defaultOptions() != nil else {
            isConfigured = false
            return
        }
        
        FirebaseApp.configure()
        isConfigured = FirebaseApp.app() != nil
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseBootstrap.configureIfPossible()
    return true
  }
}

@main
struct TrimApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseBootstrap.configureIfPossible()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
