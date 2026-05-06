import SwiftUI

struct DashboardView: View {
    @State private var overview: FinancialOverview?
    @State private var subscriptions: [Subscription] = []
    @State private var insights: [FinancialInsight] = []
    @State private var notifications: [TrimNotification] = []
    @State private var coachingData: CoachingData?
    @State private var savingsImpact: SavingsImpact?
    
    @State private var selectedTab: String = "DASHBOARD"
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.03), Color.clear]), center: .center, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                if selectedTab == "DASHBOARD" {
                    dashboardContent
                } else if selectedTab == "SAVINGS" {
                    SavingsDashboardView()
                } else if selectedTab == "SETTINGS" {
                    SettingsView()
                } else {
                    Spacer()
                    Text("\(selectedTab) view coming soon")
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    Spacer()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .task {
            do {
                overview = try await TrimApiService.shared.fetchDashboardData()
                subscriptions = try await TrimApiService.shared.fetchSubscriptions()
                insights = try await TrimApiService.shared.fetchInsights()
                notifications = try await TrimApiService.shared.fetchNotifications()
                coachingData = try await TrimApiService.shared.fetchCoaching()
                savingsImpact = try await TrimApiService.shared.fetchSavingsImpact()
            } catch {
                print("Failed to fetch data: \(error)")
            }
        }
    }
    
    // MARK: - Dashboard Content
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                intelligenceAlertsSection
                
                if let priorityAction = coachingData?.priorityAction {
                    coachingSection(action: priorityAction)
                }
                
                if let impact = savingsImpact {
                    savingsImpactSection(impact: impact)
                }
                
                portfolioPerformanceSection
                
                HStack(alignment: .top, spacing: 16) {
                    assetAllocationSection
                    upcomingBillsSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - Intelligence Alerts
    private var intelligenceAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !notifications.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(notifications) { notification in
                            HStack(spacing: 8) {
                                Image(systemName: iconName(for: notification.type))
                                    .font(.system(size: 10))
                                Text("ALERTA:")
                                    .font(.system(size: 8, weight: .black))
                                Text(notification.body)
                                    .font(.system(size: 10))
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(colorForType(notification.type).opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(colorForType(notification.type).opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    private func iconName(for type: InsightType) -> String {
        switch type {
        case .duplicateCharge: return "exclamationmark.triangle.fill"
        case .priceIncrease: return "arrow.up.right.circle.fill"
        case .subscriptionIncrease: return "arrow.up.circle.fill"
        case .hiddenSubscription: return "magnifyingglass.circle.fill"
        case .savingOpportunity: return "lightbulb.fill"
        case .unusualSpending: return "chart.line.uptrend.xyaxis.circle.fill"
        case .incomeVolatility: return "waveform.path.ecg"
        case .expenseCluster: return "square.grid.2x2.fill"
        case .opportunityInsight: return "sparkles"
        }
    }
    
    private func colorForType(_ type: InsightType) -> Color {
        switch type {
        case .duplicateCharge: return TrimDesignSystem.Colors.error
        case .priceIncrease: return TrimDesignSystem.Colors.warning
        case .subscriptionIncrease: return TrimDesignSystem.Colors.warning
        case .hiddenSubscription: return TrimDesignSystem.Colors.accentSecondary
        case .savingOpportunity: return TrimDesignSystem.Colors.accentPrimary
        case .unusualSpending: return TrimDesignSystem.Colors.accentSecondary
        case .incomeVolatility: return TrimDesignSystem.Colors.accentSecondary
        case .expenseCluster: return TrimDesignSystem.Colors.accentPrimary
        case .opportunityInsight: return TrimDesignSystem.Colors.accentPrimary
        }
    }
    
    // MARK: - Coaching
    private func coachingSection(action: CoachingRecommendation) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: coachingIcon(for: action.type))
                        .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                        .font(.title3)
                    
                    Text("COACHING")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    if action.impact == "high" {
                        Text("High Impact")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TrimDesignSystem.Colors.accentPrimary.opacity(0.2))
                            .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                            .cornerRadius(8)
                    }
                }
                
                Text(action.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(action.description)
                    .font(.subheadline)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                
                Button(action: {
                    // Action triggered
                }) {
                    HStack {
                        Text(actionText(for: action.type))
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .foregroundColor(.black)
                    .cornerRadius(TrimDesignSystem.Radius.small)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func coachingIcon(for type: String) -> String {
        switch type {
        case "save_money": return "leaf.fill"
        case "stabilize_spending": return "scale.3d"
        case "improve_habits": return "star.fill"
        default: return "bolt.fill"
        }
    }
    
    private func actionText(for type: String) -> String {
        switch type {
        case "save_money": return "Take Action"
        case "stabilize_spending": return "Review Spending"
        case "improve_habits": return "Keep it up"
        default: return "Review"
        }
    }
    
    // MARK: - Savings Impact
    private func savingsImpactSection(impact: SavingsImpact) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Prominent card content
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You've saved $\(Int(impact.totalSaved)) with Trim")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Text("$\(Int(impact.monthlySavings))/month saved")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                    }
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(TrimDesignSystem.Colors.accentPrimary.opacity(0.8))
                }
                
                if !impact.recentWins.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Wins")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        
                        ForEach(impact.recentWins.prefix(2)) { win in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                                    .font(.caption)
                                Text(win.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 28)
            }
            .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 16) {
                Image(systemName: "bell")
                    .overlay(
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 5, y: -5),
                        alignment: .topTrailing
                    )
                
                Text("J.A.")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Portfolio Performance
    private var portfolioPerformanceSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Portfolio Performance")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 24) {
                    VStack(spacing: 20) {
                        SmallRadialProgress(title: "Cash Flow", progress: 0.74, color: TrimDesignSystem.Colors.accentPrimary)
                        SmallRadialProgress(title: "Debt Ratio", progress: 0.33, color: TrimDesignSystem.Colors.accentPrimary)
                    }
                    
                    Spacer(minLength: 0)
                    
                    MainRadialProgress(progress: 0.74, returnPercentage: "+18.4%", balance: "$58,410")
                }
            }
        }
    }
    
    // MARK: - Asset Allocation
    private var assetAllocationSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Asset Allocation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                AllocationBar(title: "STOCKS", progress: 0.8, color: TrimDesignSystem.Colors.accentPrimary)
                AllocationBar(title: "BONDS", progress: 0.6, color: TrimDesignSystem.Colors.accentPrimary)
                AllocationBar(title: "CRYPTO", progress: 0.4, color: TrimDesignSystem.Colors.accentPrimary)
                AllocationBar(title: "CASH", progress: 0.2, color: TrimDesignSystem.Colors.accentPrimary)
            }
        }
    }
    
    // MARK: - Upcoming Bills
    private var upcomingBillsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming Bills")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                BillRow(title: "MORTGAGE", date: "15th", status: .paid)
                BillRow(title: "PETITIONS", date: "22th", status: .pending)
                BillRow(title: "LANNICHR", date: "15th", status: .pending)
                
                HStack {
                    Spacer()
                    Circle().fill(Color.white).frame(width: 4, height: 4)
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 4, height: 4)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Tab Bar
    private var customTabBar: some View {
        HStack {
            TabBarItem(icon: "square.grid.2x2.fill", label: "DASHBOARD", isSelected: selectedTab == "DASHBOARD") { selectedTab = "DASHBOARD" }
            TabBarItem(icon: "dollarsign.circle.fill", label: "SAVINGS", isSelected: selectedTab == "SAVINGS") { selectedTab = "SAVINGS" }
            TabBarItem(icon: "wallet.pass", label: "ACCOUNTS", isSelected: selectedTab == "ACCOUNTS") { selectedTab = "ACCOUNTS" }
            TabBarItem(icon: "gearshape", label: "SETTINGS", isSelected: selectedTab == "SETTINGS") { selectedTab = "SETTINGS" }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .background(TrimDesignSystem.Colors.surface.opacity(0.82))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.12)), alignment: .top)
        .shadow(color: Color.black.opacity(0.55), radius: 18, x: 0, y: -6)
    }
}

// MARK: - Subviews

struct MainRadialProgress: View {
    let progress: CGFloat
    let returnPercentage: String
    let balance: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 14, lineCap: .round))
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(TrimDesignSystem.Colors.accentPrimary, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 12, x: 0, y: 0)
                .overlay(
                    Circle()
                        .trim(from: max(0, progress - 0.01), to: progress)
                        .stroke(TrimDesignSystem.Colors.edgePrimary, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                )
            
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                
                Text(returnPercentage)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                Text("YTD Return")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .kerning(0.5)
                
                Text(balance)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(TrimDesignSystem.Colors.surface.opacity(0.7))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.top, 10)
            }
        }
        .padding(18)
        .trimRecessedCircle()
        .frame(width: 190, height: 190)
    }
}

struct SmallRadialProgress: View {
    let title: String
    let progress: CGFloat
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(TrimDesignSystem.Typography.caption)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .kerning(0.5)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 10, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .trim(from: max(0, progress - 0.05), to: progress)
                            .stroke(TrimDesignSystem.Colors.edgePrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    )
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
            .padding(10)
            .trimRecessedCircle()
            .frame(width: 84, height: 84)
        }
    }
}

struct AllocationBar: View {
    let title: String
    let progress: CGFloat
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(TrimDesignSystem.Typography.caption)
                .foregroundColor(color)
                .frame(width: 60, alignment: .leading)
                .kerning(0.5)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.4))
                        .shadow(color: Color.black.opacity(0.6), radius: 2, x: 1, y: 1)
                        .shadow(color: Color.white.opacity(0.05), radius: 1, x: -1, y: -1)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 8)
                        .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 2, x: 0, y: 0)
                        .overlay(
                            Rectangle()
                                .fill(TrimDesignSystem.Colors.edgePrimary)
                                .frame(width: 4, height: 8)
                                .offset(x: (geo.size.width * progress) - 2),
                            alignment: .leading
                        )
                        .clipped()
                }
                .frame(height: 8)
            }
        }
        .frame(height: 24)
    }
}

struct BillRow: View {
    let title: String
    let date: String
    enum Status { case paid, pending }
    let status: Status
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .kerning(0.5)
                Text("DUE - \(date)")
                    .font(.system(size: 8))
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary.opacity(0.6))
            }
            Spacer()
            Circle()
                .fill(status == .paid ? TrimDesignSystem.Colors.accentPrimary : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
                .shadow(color: status == .paid ? TrimDesignSystem.Colors.accentPrimary.opacity(0.5) : Color.clear, radius: 4, x: 0, y: 0)
        }
        .padding(.vertical, 4)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.05)), alignment: .bottom)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(TrimDesignSystem.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? TrimDesignSystem.Colors.accentPrimary : TrimDesignSystem.Colors.textSecondary)
            .overlay(
                isSelected ? 
                Rectangle()
                    .fill(TrimDesignSystem.Colors.accentPrimary)
                    .frame(height: 2)
                    .offset(y: -25)
                    .shadow(color: TrimDesignSystem.Colors.accentPrimary, radius: 4)
                : nil
            )
        }
        .trimPressAnimation()
    }
}
