import SwiftUI

struct SavingsDashboardView: View {
    // MARK: - Mock Data
    let yearlySavings: Double = 482.0
    let monthlySavings: Double = 40.0
    let lifetimeSavings: Double = 1250.0
    let activeOptimizations: Int = 4
    
    // Trim Color System
    let bgDeepSlate = Color(red: 15/255, green: 23/255, blue: 42/255)
    let primaryGreen = Color(red: 110/255, green: 196/255, blue: 153/255)
    let surfaceCard = Color(red: 30/255, green: 41/255, blue: 59/255).opacity(0.6)
    let cardBorder = Color.white.opacity(0.08)
    
    var body: some View {
        ZStack {
            // Background Layer
            bgDeepSlate.ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.03), Color.clear]),
                center: .top,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    headerSection
                    heroMetricSection
                    secondaryMetricsGrid
                    savingsTimeline
                    savingsBreakdown
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Impact")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.white)
            }
            Spacer()
            Circle()
                .fill(surfaceCard)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.8))
                )
                .overlay(Circle().stroke(cardBorder, lineWidth: 1))
        }
    }
    
    // MARK: - Hero Metric (Radial Arc)
    private var heroMetricSection: some View {
        VStack(spacing: 28) {
            ZStack {
                // Background Track
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(
                        primaryGreen.opacity(0.15),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .frame(width: 260, height: 260)
                
                // Progress Fill
                Circle()
                    .trim(from: 0.0, to: 0.55)
                    .stroke(
                        primaryGreen,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .frame(width: 260, height: 260)
                    .shadow(color: primaryGreen.opacity(0.35), radius: 12, x: 0, y: 0)
                
                // Typography Center
                VStack(spacing: 8) {
                    Text("$\(Int(yearlySavings))")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        // Soft structural glow
                        .shadow(color: primaryGreen.opacity(0.15), radius: 20, x: 0, y: 0)
                    
                    Text("saved this year")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                        .textCase(.uppercase)
                        .kerning(1.5)
                }
            }
            
            // Contextual Microcopy
            VStack(spacing: 6) {
                Text("You’re on track to save $620 this year")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("+12% better than last month")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(primaryGreen)
            }
        }
    }
    
    // MARK: - Secondary Metrics
    private var secondaryMetricsGrid: some View {
        HStack(spacing: 16) {
            MetricCard(
                title: "Monthly",
                value: "$\(Int(monthlySavings))",
                icon: "calendar",
                surface: surfaceCard,
                border: cardBorder
            )
            MetricCard(
                title: "Lifetime",
                value: "$\(Int(lifetimeSavings))",
                icon: "infinity",
                surface: surfaceCard,
                border: cardBorder
            )
            MetricCard(
                title: "Active",
                value: "\(activeOptimizations)",
                icon: "bolt.fill",
                surface: surfaceCard,
                border: cardBorder
            )
        }
    }
    
    // MARK: - Timeline Chart
    private var savingsTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Timeline")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach([0.3, 0.5, 0.4, 0.7, 0.6, 0.9, 1.0], id: \.self) { height in
                    VStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        primaryGreen,
                                        primaryGreen.opacity(0.2)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 120 * height)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140, alignment: .bottom)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(surfaceCard)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
            )
        }
    }
    
    // MARK: - Savings Breakdown
    private var savingsBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                BreakdownRow(
                    title: "Subscriptions canceled",
                    amount: "$320",
                    icon: "xmark.bin.fill",
                    color: Color(red: 239/255, green: 68/255, blue: 68/255), // Red
                    surface: surfaceCard,
                    border: cardBorder
                )
                BreakdownRow(
                    title: "Bills reduced",
                    amount: "$110",
                    icon: "arrow.down.right.circle.fill",
                    color: Color(red: 59/255, green: 130/255, blue: 246/255), // Blue
                    surface: surfaceCard,
                    border: cardBorder
                )
                BreakdownRow(
                    title: "Waste avoided",
                    amount: "$52",
                    icon: "leaf.fill",
                    color: primaryGreen,
                    surface: surfaceCard,
                    border: cardBorder
                )
            }
        }
    }
}

// MARK: - Subcomponents

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let surface: Color
    let border: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.white.opacity(0.4))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                    .textCase(.uppercase)
                    .kerning(0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
        )
    }
}

struct BreakdownRow: View {
    let title: String
    let amount: String
    let icon: String
    let color: Color
    let surface: Color
    let border: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                )
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
        )
    }
}
