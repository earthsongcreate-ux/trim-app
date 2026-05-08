import SwiftUI

struct SavingsDashboardView: View {
    @State private var savingsImpact: SavingsImpact?
    @State private var isLoading = true
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.03), Color.clear]), center: .center, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: TrimDesignSystem.Colors.accentPrimary))
                    .scaleEffect(1.5)
            } else if let impact = savingsImpact, !impact.recentWins.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection(impact: impact)
                        heroCard(impact: impact)
                        groupedWinsList(impact: impact)
                        privacyFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            } else {
                emptyState
            }
        }
        .task {
            do {
                savingsImpact = try await TrimApiService.shared.fetchSavingsImpact()
                withAnimation {
                    isLoading = false
                    appearAnimation = true
                }
            } catch {
                print("Failed to fetch savings: \(error)")
                withAnimation { isLoading = false }
            }
        }
    }
    
    // MARK: - 1. HEADER
    private func headerSection(impact: SavingsImpact) -> some View {
        HStack {
            Text("Savings Detail")
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - 2. HERO CARD
    private func heroCard(impact: SavingsImpact) -> some View {
        PremiumGlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOTAL SAVED")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .kerning(1.5)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("$")
                            .font(TrimDesignSystem.Typography.header)
                            .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                        
                        Text("\(Int(impact.totalSaved))")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                            .shadow(color: TrimDesignSystem.Colors.accentPrimary.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    
                    Text("That's $\(Int(impact.monthlySavings))/month back")
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                RadialProgressDial(progress: appearAnimation ? 0.75 : 0.0)
                    .frame(width: 80, height: 80)
            }
            .padding(.vertical, 8)
        }
        .shadow(color: Color.black.opacity(0.4), radius: 12, x: 6, y: 6)
        .shadow(color: Color.white.opacity(0.04), radius: 2, x: -1, y: -1)
    }
    
    // MARK: - 3. GROUPED LIST
    private func groupedWinsList(impact: SavingsImpact) -> some View {
        let now = Date()
        let calendar = Calendar.current
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        
        func parseDate(_ str: String) -> Date {
            return formatter.date(from: str) ?? fallbackFormatter.date(from: str) ?? now
        }
        
        let sortedWins = impact.recentWins.sorted { parseDate($0.date) > parseDate($1.date) }
        
        let thisMonth = sortedWins.filter {
            calendar.isDate(parseDate($0.date), equalTo: now, toGranularity: .month)
        }
        
        let last3Months = sortedWins.filter {
            let d = parseDate($0.date)
            let diff = calendar.dateComponents([.month], from: d, to: now).month ?? 0
            return diff > 0 && diff <= 3
        }
        
        let older = sortedWins.filter {
            let diff = calendar.dateComponents([.month], from: parseDate($0.date), to: now).month ?? 0
            return diff > 3
        }
        
        return VStack(alignment: .leading, spacing: 24) {
            if !thisMonth.isEmpty {
                winGroup(title: "This Month", wins: thisMonth)
            }
            if !last3Months.isEmpty {
                winGroup(title: "Last 3 Months", wins: last3Months)
            }
            if !older.isEmpty {
                winGroup(title: "Older", wins: older)
            }
        }
    }
    
    private func winGroup(title: String, wins: [SavingsWin]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            
            PremiumGlassCard(.inset) {
                VStack(spacing: 0) {
                    ForEach(Array(wins.enumerated()), id: \.element.id) { index, win in
                        SavingsWinRow(win: win, delay: Double(index) * 0.1)
                        if index < wins.count - 1 {
                            Divider().background(Color.white.opacity(0.1))
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - EMPTY STATE
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 64))
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            Text("No Savings Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Your savings will appear here once Trim starts optimizing your finances.")
                .font(.subheadline)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - PRIVACY FOOTER
    private var privacyFooter: some View {
        HStack(spacing: TrimDesignSystem.Spacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11))
            Text("Secure. Private. Your data stays yours.")
                .font(.system(size: 12))
        }
        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
}

// MARK: - Subcomponents

struct BreakdownRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
        }
    }
}

struct SavingsWinRow: View {
    let win: SavingsWin
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colorForType(win.type).opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: iconForType(win.type))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(colorForType(win.type))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(win.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                HStack(spacing: 6) {
                    Text(tagForType(win.type))
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorForType(win.type).opacity(0.15))
                        .foregroundColor(colorForType(win.type))
                        .cornerRadius(4)
                    
                    Text(formattedDate(win.date))
                        .font(.caption2)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(win.frequency == "yearly" ? "$\(Int(win.amount * 12))/yr" : "$\(Int(win.amount))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                
                if win.frequency == "yearly" {
                    Text("Saved $\(Int(win.amount))/mo")
                        .font(.caption2)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                isVisible = true
            }
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "subscription_cancel": return "slash.circle.fill"
        case "price_reduction": return "arrow.down.right.circle.fill"
        case "duplicate": return "arrow.uturn.backward.circle.fill"
        default: return "star.circle.fill"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "subscription_cancel": return TrimDesignSystem.Colors.accentSecondary
        case "price_reduction": return TrimDesignSystem.Colors.accentPrimary
        case "duplicate": return .blue
        default: return .purple
        }
    }
    
    private func tagForType(_ type: String) -> String {
        switch type {
        case "subscription_cancel": return "SUBSCRIPTION"
        case "price_reduction": return "NEGOTIATED"
        case "duplicate": return "REFUND"
        default: return "BEHAVIOR"
        }
    }
    
    private func formattedDate(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        
        guard let d = formatter.date(from: isoDate) ?? fallback.date(from: isoDate) else { return "" }
        let displayFmt = DateFormatter()
        displayFmt.dateFormat = "MMM d"
        return displayFmt.string(from: d)
    }
}

struct MilestoneItem: View {
    let amount: Int
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(isCompleted ? TrimDesignSystem.Colors.accentPrimary : Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 48, height: 48)
                
                if isCompleted {
                    Circle()
                        .fill(TrimDesignSystem.Colors.accentPrimary.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .shadow(color: TrimDesignSystem.Colors.accentPrimary.opacity(0.5), radius: 8)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Color.white.opacity(0.3))
                        .font(.system(size: 16))
                }
            }
            
            Text("$\(amount)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isCompleted ? TrimDesignSystem.Colors.textPrimary : TrimDesignSystem.Colors.textSecondary)
        }
    }
}

struct RadialProgressDial: View {
    var progress: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(TrimDesignSystem.Colors.accentPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 10, x: 0, y: 0)
                .overlay(
                    Circle()
                        .trim(from: max(0, progress - 0.02), to: progress)
                        .stroke(TrimDesignSystem.Colors.edgePrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                )
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                .font(.system(size: 20))
        }
        .padding(8)
        .trimRecessedCircle()
    }
}

struct AnimatedNumberText: View {
    var value: Double
    
    var body: some View {
        Text("\(Int(value))")
            // In a real app with iOS 16+, `contentTransition(.numericText())` is perfect here.
            // For general compatibility, we just display the binding which updates rapidly.
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
