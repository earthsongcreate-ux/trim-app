import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
            
            SavingsDashboardView()
                .tabItem {
                    Label("Savings", systemImage: "target")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(TrimDesignSystem.Colors.accentPrimary)
    }
}
