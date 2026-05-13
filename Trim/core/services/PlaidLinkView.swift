import SwiftUI
#if canImport(LinkKit)
import LinkKit
#endif

// MARK: - PlaidLinkView

/// A `UIViewControllerRepresentable` that bridges the Plaid Link UIKit handler
/// into SwiftUI's view hierarchy.
///
/// Presents the Plaid Link flow as a modal. The handler is obtained from
/// `PlaidLinkManager` and must be in `.ready` state before this view appears.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showPlaidLink) {
///     PlaidLinkView()
///         .environmentObject(plaidManager)
/// }
/// ```
///
/// **Important:** This view is presentation-only. All result handling is managed
/// by `PlaidLinkManager` via its callback system.
#if canImport(LinkKit)
struct PlaidLinkView: UIViewControllerRepresentable {
    
    @EnvironmentObject private var plaidManager: PlaidLinkManager
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Present Link handler when ready and not already presented
        guard plaidManager.state == .ready,
              uiViewController.presentedViewController == nil else {
            return
        }
        
        // Plaid's handler.open() presents a modal from the given VC
        if let handler = getHandler() {
            handler.open(presentUsing: .viewController(uiViewController))
        }
    }
    
    /// Accesses the internal handler from PlaidLinkManager.
    ///
    /// The handler is a private property of PlaidLinkManager,
    /// accessed here via a controlled method.
    private func getHandler() -> Handler? {
        // Access through manager's internal handler
        // This requires PlaidLinkManager to expose the handler for presentation
        return plaidManager.handler
    }
}
#else
struct PlaidLinkView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Plaid LinkKit not installed")
                .font(.headline)
            Text("This build can’t show the bank-connection flow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
#endif
