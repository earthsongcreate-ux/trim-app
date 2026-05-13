import Foundation
#if canImport(Combine)
import Combine
#endif
#if canImport(LinkKit)
import LinkKit
#endif

// MARK: - PlaidLinkManager

/// Manages the Plaid Link lifecycle — configuration, launch, and result handling.
///
/// This service wraps the Plaid Link iOS SDK and exposes reactive state
/// for SwiftUI consumption. It handles the full Link flow:
///
/// 1. Fetch a `link_token` from the Trim backend
/// 2. Configure and present the Plaid Link UI
/// 3. Capture the `public_token` on successful account connection
/// 4. Forward the token to the backend for exchange (separate concern)
///
/// **Security model:**
/// - No banking credentials are stored or accessed by this service.
/// - Only the `public_token` is handled on the client — it is a single-use,
///   short-lived token that must be exchanged server-side for an `access_token`.
/// - The `link_token` is fetched per-session and expires after use.
///
/// **Important:** Requires `LinkKit` (Plaid Link iOS SDK) via SPM or CocoaPods.
/// Add to your project: `https://github.com/plaid/plaid-link-ios`
final class PlaidLinkManager: ObservableObject {
    
    static let shared = PlaidLinkManager()
    
    // MARK: - Published State
    
    /// Current state of the Link flow.
    @Published private(set) var state: LinkState = .idle
    
    /// The institution name after successful connection (e.g., "Chase", "Wells Fargo").
    @Published private(set) var connectedInstitution: String?
    
    /// The number of accounts connected in the last successful session.
    @Published private(set) var connectedAccountCount: Int = 0
    
    // MARK: - Internal State
    
    /// The Plaid Link handler — retained during the active session.
    /// Accessible for presentation by `PlaidLinkView`.
#if canImport(LinkKit)
    private(set) var handler: Handler?
#endif
    
    /// The public token received from a successful Link session.
    /// Must be sent to the backend immediately for exchange.
    private(set) var publicToken: String?
    
    // MARK: - State Machine
    
    /// Represents the current phase of the Plaid Link flow.
    enum LinkState: Equatable {
        /// No active Link session.
        case idle
        
        /// Fetching link_token from the Trim backend.
        case fetchingToken
        
        /// Link UI is ready to present.
        case ready
        
        /// Link UI is currently presented and active.
        case active
        
        /// User successfully connected accounts.
        case success
        
        /// User exited the Link flow without completing.
        case exited
        
        /// An error occurred during the flow.
        case error(String)
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public API
    
    /// Initiates the Plaid Link flow by fetching a link_token and configuring the handler.
    ///
    /// Call this before presenting the Link UI. On success, `state` transitions to `.ready`
    /// and the handler is prepared for presentation via `PlaidLinkView`.
    @MainActor
    func prepareLinkSession() async {
        guard state == .idle || state == .exited || state.isError else { return }
        
        state = .fetchingToken
        publicToken = nil
        connectedInstitution = nil
        connectedAccountCount = 0

#if canImport(LinkKit)
        do {
            let linkToken = try await fetchLinkToken()
            configureLinkHandler(with: linkToken)
            state = .ready
        } catch let error as NetworkError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error(error.localizedDescription)
        }
#else
        state = .error("Plaid LinkKit is not installed in this build.")
#endif
    }
    
    /// Resets all state back to idle. Call when dismissing the connection UI.
    @MainActor
    func reset() {
        state = .idle
#if canImport(LinkKit)
        handler = nil
#endif
        publicToken = nil
        connectedInstitution = nil
        connectedAccountCount = 0
    }
    
    /// Sends the public token to the Trim backend for exchange.
    ///
    /// The backend will exchange this for a permanent `access_token` via
    /// Plaid's `/item/public_token/exchange` endpoint.
    ///
    /// - Returns: `true` if the token was sent successfully.
    @MainActor
    func sendTokenToBackend() async -> Bool {
        guard let token = publicToken else { return false }
        
        do {
            try await exchangePublicToken(token)
            return true
        } catch let error as NetworkError {
            state = .error(error.localizedDescription)
            return false
        } catch {
            state = .error(error.localizedDescription)
            return false
        }
    }
    
    // MARK: - Link Handler Configuration
    
    /// Configures the Plaid Link handler with the provided link_token.
#if canImport(LinkKit)
    private func configureLinkHandler(with linkToken: String) {
        let configuration = LinkTokenConfiguration(token: linkToken) { [weak self] result in
            self?.handleLinkSuccess(result)
        }
        
        // Configure event handling
        var config = configuration
        config.onExit = { [weak self] exit in
            self?.handleLinkExit(exit)
        }
        config.onEvent = { [weak self] event in
            self?.handleLinkEvent(event)
        }
        
        let result = Plaid.create(config)
        switch result {
        case .success(let handler):
            self.handler = handler
        case .failure(let error):
            DispatchQueue.main.async {
                self.state = .error("Configuration error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Callback Handlers
    
    /// Handles a successful Link session.
    ///
    /// Captures the public_token and institution metadata.
    /// The token must be exchanged server-side — never stored locally.
    private func handleLinkSuccess(_ result: LinkSuccess) {
        DispatchQueue.main.async {
            self.publicToken = result.publicToken
            self.connectedInstitution = result.metadata.institution.name
            self.connectedAccountCount = result.metadata.accounts.count
            self.state = .success
        }
    }
    
    /// Handles Link exit (user dismissed or error during flow).
    private func handleLinkExit(_ exit: LinkExit) {
        DispatchQueue.main.async {
            if let error = exit.error {
                self.state = .error(error.localizedDescription)
            } else {
                // User voluntarily closed — not an error
                self.state = .exited
            }
        }
    }
    
    /// Handles Link events for analytics/debugging.
    ///
    /// Events include: OPEN, TRANSITION_VIEW, SELECT_INSTITUTION, etc.
    /// These are informational only and do not affect the state machine.
    private func handleLinkEvent(_ event: LinkEvent) {
        #if DEBUG
        print("[PlaidLink] Event: \(event.eventName)")
        #endif
        
        if String(describing: event.eventName) == "OPEN" {
            DispatchQueue.main.async {
                self.state = .active
            }
        }
    }
#else
    private func configureLinkHandler(with linkToken: String) {
        DispatchQueue.main.async {
            self.state = .error("Plaid LinkKit is not installed in this build.")
        }
    }
#endif
    
    // MARK: - Network (Backend Integration)
    
    /// Fetches a link_token from the Trim backend.
    ///
    /// The backend calls Plaid's `/link/token/create` endpoint and returns
    /// a short-lived token for this session.
    private func fetchLinkToken() async throws -> String {
        return try await TrimApiService.shared.createPlaidLinkToken()
    }
    
    /// Sends the public_token to the Trim backend for exchange.
    ///
    /// The backend exchanges it for a permanent `access_token` via
    /// Plaid's `/item/public_token/exchange` and stores it securely.
    /// The access_token never reaches the client.
    private func exchangePublicToken(_ token: String) async throws {
        try await TrimApiService.shared.exchangePlaidPublicToken(token, institutionName: connectedInstitution ?? "Unknown")
    }
}

// MARK: - Response Models

/// Response from POST /api/plaid/create-link-token
private struct LinkTokenResponse: Decodable {
    let success: Bool
    let linkToken: String
}

/// Response from POST /api/plaid/exchange-token
private struct ExchangeTokenResponse: Decodable {
    let success: Bool
    let connection: ConnectionInfo?
}

/// Sanitized connection metadata returned by the backend.
/// Never contains access_token — that stays server-side.
private struct ConnectionInfo: Decodable {
    let id: String
    let itemId: String
    let institutionName: String
    let accounts: [AccountInfo]
    let connectedAt: String
    let status: String
}

private struct AccountInfo: Decodable {
    let id: String
    let name: String
    let mask: String?
    let type: String
    let subtype: String?
}

// MARK: - State Helpers

extension PlaidLinkManager.LinkState {
    
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}
