import SwiftUI

enum TrimDesignSystem {
    enum Colors {
        static let background = Color(hex: "0F172A")
        static let surface = Color(hex: "1E293B")
        static let accentPrimary = Color(hex: "16A34A")
        static let accentSecondary = Color(hex: "2563EB")
        static let glowPrimary = Color(hex: "16A34A").opacity(0.18)
        static let edgePrimary = Color(hex: "16A34A").opacity(0.35)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let success = Color(hex: "16A34A")
        static let warning = Color(hex: "D97706")
        static let error = Color(hex: "DC2626")
    }
    
    enum Spacing {
        static let xs: CGFloat = 8
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 14
        static let large: CGFloat = 18
    }
    
    enum Typography {
        static let header = Font.custom("Inter-SemiBold", size: 24, relativeTo: .title)
        static let subheader = Font.custom("Inter-SemiBold", size: 18, relativeTo: .title3)
        static let body = Font.custom("Inter-Regular", size: 16, relativeTo: .body)
        static let caption = Font.custom("Inter-Regular", size: 12, relativeTo: .caption)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Components

struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(GlassCardStyle())
    }
}

private struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: TrimDesignSystem.Radius.medium, style: .continuous)
        
        return content
            .padding(TrimDesignSystem.Spacing.m)
            .background(.ultraThinMaterial)
            .background(TrimDesignSystem.Colors.surface.opacity(0.72))
            .clipShape(shape)
            .overlay(
                shape.stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .overlay(
                shape
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(x: 0, y: 1)
                    .mask(
                        shape.fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 18, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.05), radius: 1, x: -1, y: -1)
    }
}

// MARK: - Neumorphic Depth Modifier
struct NeumorphicInset: ViewModifier {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = TrimDesignSystem.Radius.medium) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(TrimDesignSystem.Colors.background.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.75), lineWidth: 10)
                    .blur(radius: 10)
                    .offset(x: 6, y: 6)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black, Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .blur(radius: 8)
                    .offset(x: -4, y: -4)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .compositingGroup()
    }
}

struct RecessedCircle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(TrimDesignSystem.Colors.background.opacity(0.55))
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.75), lineWidth: 10)
                    .blur(radius: 10)
                    .offset(x: 6, y: 6)
                    .mask(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black, Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .blur(radius: 8)
                    .offset(x: -4, y: -4)
                    .mask(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.black]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .clipShape(Circle())
            .compositingGroup()
    }
}

extension View {
    func trimInset(cornerRadius: CGFloat = TrimDesignSystem.Radius.medium) -> some View {
        self.modifier(NeumorphicInset(cornerRadius: cornerRadius))
    }
    
    func trimRecessedCircle() -> some View {
        self.modifier(RecessedCircle())
    }
    
    func trimPressAnimation() -> some View {
        self.buttonStyle(TrimScaleButtonStyle())
    }
}

struct TrimScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
