import Foundation
import SwiftUI
import Combine

@MainActor
class PaywallManager: ObservableObject {
    static let shared = PaywallManager()
    
    @Published var isShowingPaywall: Bool = false
    @Published var activePaywallData: PaywallData? = nil
    
    private init() {}
    
    /// Evaluate if paywall should be shown.
    /// Contexts: "app_open", "savings_viewed", "action_completed"
    func triggerEvaluation(context: String) {
        Task {
            if let response = try? await TrimApiService.shared.evaluatePaywall(context: context) {
                if response.showPaywall, let paywall = response.paywall {
                    self.activePaywallData = paywall
                    self.isShowingPaywall = true
                }
            }
        }
    }
    
    func dismissPaywall() {
        self.isShowingPaywall = false
        self.activePaywallData = nil
        Task {
            try? await TrimApiService.shared.interactWithPaywall(action: "dismiss")
        }
    }
    
    func convertUser() {
        self.isShowingPaywall = false
        self.activePaywallData = nil
        Task {
            try? await TrimApiService.shared.interactWithPaywall(action: "convert")
            // Normally would trigger Apple IAP logic here
        }
    }
}
