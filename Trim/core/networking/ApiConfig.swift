import Foundation

enum ApiConfig {
    static var baseURL: String {
        if let env = ProcessInfo.processInfo.environment["TRIM_API_URL"], !env.isEmpty {
            return env
        }
        if let info = Bundle.main.object(forInfoDictionaryKey: "TRIM_API_URL") as? String, !info.isEmpty {
            return info
        }
        return "http://127.0.0.1:8000"
    }
}

