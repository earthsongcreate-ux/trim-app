import SwiftUI

// MARK: - Inline Feedback Row

/// Compact inline feedback component for 1-tap confirm/correct.
/// Attaches to insight cards as a bottom bar.
///
/// UX rules:
/// - One tap submits instantly (no confirmation dialog)
/// - Visual state change confirms submission
/// - Optional correction sheet on 👎 tap
struct InlineFeedbackRow: View {
    let insight: FinancialInsight
    @Binding var feedbackState: FeedbackState
    @State private var showCorrectionSheet = false
    
    var body: some View {
        HStack(spacing: 0) {
            switch feedbackState {
            case .none:
                feedbackButtons
            case .confirmed:
                confirmedState
            case .corrected:
                correctedState
            case .submitting:
                submittingState
            }
        }
        .padding(.top, 8)
        .sheet(isPresented: $showCorrectionSheet) {
            CorrectionSheetView(
                insight: insight,
                onSubmit: { correction in
                    submitCorrection(correction)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - States
    
    private var feedbackButtons: some View {
        HStack(spacing: 12) {
            // Confirm button (👍)
            Button {
                submitConfirmation()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 12))
                    Text("Correct")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            
            // Incorrect button (👎)
            Button {
                showCorrectionSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsdown.fill")
                        .font(.system(size: 12))
                    Text("Incorrect")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    private var confirmedState: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(TrimDesignSystem.Colors.success)
            Text("Thanks for confirming")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TrimDesignSystem.Colors.success.opacity(0.8))
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private var correctedState: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(TrimDesignSystem.Colors.accentSecondary)
            Text("Updated — we'll learn from this")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TrimDesignSystem.Colors.accentSecondary.opacity(0.8))
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private var submittingState: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.6)
                .tint(TrimDesignSystem.Colors.textSecondary)
            Text("Saving...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Submission
    
    private func submitConfirmation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackState = .submitting
        }
        
        Task {
            await FeedbackService.shared.submitConfirmation(for: insight)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    feedbackState = .confirmed
                }
            }
        }
    }
    
    private func submitCorrection(_ correction: FeedbackCorrection) {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackState = .submitting
        }
        
        Task {
            await FeedbackService.shared.submitCorrection(for: insight, correction: correction)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    feedbackState = .corrected
                }
            }
        }
    }
}

// MARK: - Correction Sheet

/// Quick-correction flow presented as a half-sheet.
/// All options are tap-based — no typing required.
struct CorrectionSheetView: View {
    let insight: FinancialInsight
    let onSubmit: (FeedbackCorrection) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMerchant: String?
    @State private var selectedCategory: String?
    @State private var isRecurring: Bool?
    @State private var correctionMode: CorrectionMode = .none
    
    enum CorrectionMode {
        case none, merchant, category, recurring
    }
    
    private let categories: [(String, String)] = [
        ("subscriptions", "Subscriptions"),
        ("transport", "Transport"),
        ("food", "Food & Dining"),
        ("shopping", "Shopping"),
        ("income", "Income"),
        ("utilities", "Utilities"),
        ("housing", "Housing"),
        ("entertainment", "Entertainment"),
        ("software", "Software"),
        ("insurance", "Insurance"),
        ("healthcare", "Healthcare"),
        ("other", "Other"),
    ]
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 6) {
                    Text("What should we fix?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Tap the incorrect detail below")
                        .font(.subheadline)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
                .padding(.top, 12)
                
                // Correction options
                VStack(spacing: 12) {
                    // Merchant correction
                    correctionOption(
                        icon: "building.2.fill",
                        label: "Merchant",
                        current: insight.merchant ?? insight.description,
                        mode: .merchant,
                        isActive: correctionMode == .merchant
                    )
                    
                    // Category correction
                    correctionOption(
                        icon: "tag.fill",
                        label: "Category",
                        current: insight.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        mode: .category,
                        isActive: correctionMode == .category
                    )
                    
                    // Recurring correction
                    correctionOption(
                        icon: "arrow.clockwise.circle.fill",
                        label: "Not Recurring",
                        current: "Mark as one-time charge",
                        mode: .recurring,
                        isActive: correctionMode == .recurring
                    )
                }
                .padding(.horizontal)
                
                // Category picker (shown when category mode is active)
                if correctionMode == .category {
                    categoryPicker
                }
                
                Spacer()
                
                // Submit button
                if hasChanges {
                    Button {
                        let correction = FeedbackCorrection(
                            merchant: selectedMerchant,
                            category: selectedCategory,
                            isRecurring: isRecurring
                        )
                        onSubmit(correction)
                        dismiss()
                    } label: {
                        Text("Apply Correction")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(TrimDesignSystem.Colors.accentPrimary)
                            .foregroundColor(.black)
                            .cornerRadius(TrimDesignSystem.Radius.medium)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func correctionOption(
        icon: String,
        label: String,
        current: String,
        mode: CorrectionMode,
        isActive: Bool
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if correctionMode == mode {
                    correctionMode = .none
                    clearSelection(for: mode)
                } else {
                    correctionMode = mode
                    applyDefaultSelection(for: mode)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? TrimDesignSystem.Colors.accentPrimary : TrimDesignSystem.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(current)
                        .font(.system(size: 12))
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? TrimDesignSystem.Colors.accentPrimary : Color.white.opacity(0.15))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small)
                    .fill(isActive ? TrimDesignSystem.Colors.accentPrimary.opacity(0.08) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.small)
                    .stroke(isActive ? TrimDesignSystem.Colors.accentPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.0) { key, label in
                    Button {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selectedCategory = key
                        }
                    } label: {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory == key ? .black : TrimDesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == key
                                          ? TrimDesignSystem.Colors.accentPrimary
                                          : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Helpers
    
    private var hasChanges: Bool {
        selectedMerchant != nil || selectedCategory != nil || isRecurring != nil
    }
    
    private func applyDefaultSelection(for mode: CorrectionMode) {
        switch mode {
        case .merchant:
            // No default — user would need a text field for custom merchant
            // For V1, just marking merchant as "incorrect" is enough
            selectedMerchant = "corrected"
        case .category:
            break // User picks from the horizontal category scroller
        case .recurring:
            isRecurring = false
        case .none:
            break
        }
    }
    
    private func clearSelection(for mode: CorrectionMode) {
        switch mode {
        case .merchant: selectedMerchant = nil
        case .category: selectedCategory = nil
        case .recurring: isRecurring = nil
        case .none: break
        }
    }
}

// MARK: - Feedback Service

/// Handles feedback submission to the backend.
/// Encapsulates all network logic for the feedback loop.
class FeedbackService {
    static let shared = FeedbackService()
    
    private let baseURL: String = {
        ProcessInfo.processInfo.environment["TRIM_API_URL"] ?? "http://localhost:3001"
    }()
    
    private init() {}
    
    /// Submits a confirmation (👍) for an insight.
    func submitConfirmation(for insight: FinancialInsight) async {
        let request = FeedbackRequest(
            userId: currentUserId(),
            targetId: insight.id.uuidString,
            targetType: "insight",
            feedbackType: "confirm",
            originalPrediction: FeedbackPrediction(
                merchant: insight.merchant,
                category: insight.type.rawValue,
                isRecurring: nil
            ),
            userCorrection: nil
        )
        
        await send(request)
    }
    
    /// Submits a correction (👎) for an insight.
    func submitCorrection(for insight: FinancialInsight, correction: FeedbackCorrection) async {
        let request = FeedbackRequest(
            userId: currentUserId(),
            targetId: insight.id.uuidString,
            targetType: "insight",
            feedbackType: "correct",
            originalPrediction: FeedbackPrediction(
                merchant: insight.merchant,
                category: insight.type.rawValue,
                isRecurring: nil
            ),
            userCorrection: correction
        )
        
        await send(request)
    }
    
    // MARK: - Private
    
    private func send(_ feedback: FeedbackRequest) async {
        guard let url = URL(string: "\(baseURL)/api/feedback") else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(feedback)
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("[FeedbackService] Server returned \(httpResponse.statusCode)")
            }
        } catch {
            // Fail silently — feedback is best-effort, not critical path
            print("[FeedbackService] Submission failed: \(error.localizedDescription)")
        }
    }
    
    private func currentUserId() -> String {
        // In production, use the authenticated user's ID
        // For now, use a stable device-based identifier
        return UIDevice.current.identifierForVendor?.uuidString ?? "anonymous"
    }
}
