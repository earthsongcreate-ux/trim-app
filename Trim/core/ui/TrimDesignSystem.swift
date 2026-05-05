import SwiftUI

/// Trim UI/UX Design System Global Definitions
enum TrimDesign {
    
    // MARK: - Colors
    enum Colors {
        static let background = Color(hex: "0F172A")
        static let surface = Color(hex: "1E293B").opacity(0.7)
        static let primary = Color(hex: "6ec499") // New Trim green
        static let secondary = Color(hex: "3B82F6")
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let surfaceBorder = Color.white.opacity(0.1)
    }
    
    // MARK: - Constants
    enum Layout {
        static let cornerRadius: CGFloat = 8
        static let padding: CGFloat = 16
        // Spacing should be multiples of 8 (8, 16, 24, 32, etc)
    }
    
    enum FontStyle {
        static let header = Font.custom("Inter-SemiBold", size: 24, relativeTo: .title)
        static let subheader = Font.custom("Inter-SemiBold", size: 18, relativeTo: .title3)
        static let body = Font.custom("Inter-Regular", size: 16, relativeTo: .body)
        static let caption = Font.custom("Inter-Regular", size: 12, relativeTo: .caption)
    }
}

// MARK: - Modifiers

struct GlassmorphicSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(TrimDesign.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: TrimDesign.Layout.cornerRadius)
                    .stroke(TrimDesign.Colors.surfaceBorder, lineWidth: 1)
            )
            .cornerRadius(TrimDesign.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.35), radius: 16, x: 6, y: 6)
            .shadow(color: Color.white.opacity(0.03), radius: 12, x: -4, y: -4)
    }
}

struct NeumorphicInset: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Outer container background
            .background(TrimDesign.Colors.background)
            .cornerRadius(TrimDesign.Layout.cornerRadius)
            // Inner shadow representation in SwiftUI using overlays
            .overlay(
                RoundedRectangle(cornerRadius: TrimDesign.Layout.cornerRadius)
                    .stroke(Color.black.opacity(0.4), lineWidth: 4)
                    .blur(radius: 4)
                    .offset(x: 4, y: 4)
                    .mask(RoundedRectangle(cornerRadius: TrimDesign.Layout.cornerRadius).fill(LinearGradient(Color.black, Color.clear)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TrimDesign.Layout.cornerRadius)
                    .stroke(Color.white.opacity(0.05), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: -2, y: -2)
                    .mask(RoundedRectangle(cornerRadius: TrimDesign.Layout.cornerRadius).fill(LinearGradient(Color.clear, Color.black)))
            )
    }
}

extension View {
    func trimGlassSurface() -> some View {
        self.modifier(GlassmorphicSurface())
    }
    
    func trimInset() -> some View {
        self.modifier(NeumorphicInset())
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

// MARK: - Components

struct TrimRadialDial: View {
    let percentage: Double // 0.0 to 1.0
    let label: String
    let valueText: String
    
    var body: some View {
        ZStack {
            // Base track (dark inset)
            Circle()
                .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .shadow(color: .black.opacity(0.4), radius: 4, x: insetShadowOffset(), y: insetShadowOffset())
            
            // Active stroke
            Circle()
                .trim(from: 0, to: CGFloat(percentage))
                .stroke(TrimDesign.Colors.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: TrimDesign.Colors.primary.opacity(0.5), radius: 8, x: 0, y: 0) // Glow
            
            VStack(spacing: 4) {
                Text(valueText)
                    .font(TrimDesign.FontStyle.header)
                    .foregroundColor(TrimDesign.Colors.textPrimary)
                
                Text(label)
                    .font(TrimDesign.FontStyle.caption)
                    .foregroundColor(TrimDesign.Colors.textSecondary)
                    .kerning(0.5) // Slight letter spacing
            }
        }
        .padding(16)
        .trimInset() // Carved effect container
    }
    
    private func insetShadowOffset() -> CGFloat { 2.0 }
}

struct TrimHorizontalBar: View {
    let label: String
    let percentage: Double
    let isSecondary: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Text(label)
                .font(TrimDesign.FontStyle.caption)
                .foregroundColor(TrimDesign.Colors.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSecondary ? TrimDesign.Colors.secondary : TrimDesign.Colors.primary)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                        .shadow(color: (isSecondary ? TrimDesign.Colors.secondary : TrimDesign.Colors.primary).opacity(0.5), radius: 4, x: 0, y: 0)
                }
                .frame(height: 8)
            }
        }
        .frame(height: 24)
    }
}
