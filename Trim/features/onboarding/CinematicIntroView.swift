import SwiftUI

enum IntroPhase {
    case initial
    case logo
    case scanning
    case result
    case cta
}

struct CinematicIntroView: View {
    var onComplete: () -> Void
    
    @State private var phase: IntroPhase = .initial
    @State private var scanText = "Analyzing patterns..."
    @State private var scanProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            
            // Subtle animated background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    TrimDesignSystem.Colors.accentPrimary.opacity(phase == .scanning || phase == .result || phase == .cta ? 0.03 : 0.01),
                    Color.clear
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0), value: phase)
            
            VStack {
                Spacer()
                
                ZStack {
                    // LOGO PHASE (0-2s)
                    if phase == .logo || phase == .initial {
                        VStack(spacing: TrimDesignSystem.Spacing.m) {
                            HStack(spacing: TrimDesignSystem.Spacing.s) {
                                Text("TRIM")
                                    .font(.system(size: 48, weight: .heavy, design: .default))
                                    .kerning(2.0)
                                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                            }
                            
                            Text("Your finances. Under control.")
                                .font(TrimDesignSystem.Typography.body)
                                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        }
                        .opacity(phase == .logo ? 1 : 0)
                        .transition(.opacity)
                    }
                    
                    // SCANNING & RESULT PHASE (2-10s)
                    if phase == .scanning || phase == .result || phase == .cta {
                        VStack(spacing: TrimDesignSystem.Spacing.xl) {
                            ZStack {
                                // Background track
                                Circle()
                                    .stroke(Color.black.opacity(0.4), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .shadow(color: .black.opacity(0.6), radius: 6, x: 4, y: 4)
                                    .shadow(color: .white.opacity(0.05), radius: 2, x: -1, y: -1)
                                
                                // Active stroke
                                Circle()
                                    .trim(from: 0, to: scanProgress)
                                    .stroke(TrimDesignSystem.Colors.accentPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 2, x: 0, y: 0)
                                    .overlay(
                                        Circle()
                                            .trim(from: max(0, scanProgress - 0.02), to: scanProgress)
                                            .stroke(TrimDesignSystem.Colors.edgePrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                    )
                                
                                // Inner Content
                                VStack(spacing: TrimDesignSystem.Spacing.xs) {
                                    if phase == .scanning {
                                        Text(scanText)
                                            .font(TrimDesignSystem.Typography.caption)
                                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                                            .transition(.opacity)
                                            .id(scanText)
                                    } else {
                                        VStack(spacing: 0) {
                                            Text("$186")
                                                .font(.system(size: 48, weight: .bold))
                                                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                                                .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 2, x: 0, y: 0)
                                            Text("found")
                                                .font(TrimDesignSystem.Typography.caption)
                                                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                                                .textCase(.uppercase)
                                                .kerning(1.0)
                                        }
                                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                                    }
                                }
                            }
                            .frame(width: 240, height: 240)
                            .background(
                                RadialGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.1)]), center: .center, startRadius: 0, endRadius: 120)
                            )
                            .cornerRadius(120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 120)
                                    .stroke(Color.black.opacity(0.7), lineWidth: 8)
                                    .blur(radius: 6)
                                    .offset(x: 6, y: 6)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 120).fill(
                                            LinearGradient(
                                                colors: [Color.black, Color.clear],
                                                startPoint: .bottomTrailing,
                                                endPoint: .topLeading
                                            )
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 120)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 2)
                                    .blur(radius: 2)
                                    .offset(x: -1, y: -1)
                                    .mask(
                                        RoundedRectangle(cornerRadius: 120).fill(
                                            LinearGradient(
                                                colors: [Color.clear, Color.black],
                                                startPoint: .bottomTrailing,
                                                endPoint: .topLeading
                                            )
                                        )
                                    )
                            )
                            
                            if phase == .result || phase == .cta {
                                Text("Across 4 subscriptions")
                                    .font(TrimDesignSystem.Typography.body)
                                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                                    .transition(.opacity)
                            }
                        }
                        .transition(.opacity)
                    }
                }
                
                Spacer()
                
                // CTA PHASE (8-10s)
                ZStack {
                    if phase == .cta {
                        VStack(spacing: TrimDesignSystem.Spacing.m) {
                            Button(action: onComplete) {
                                Text("See where you can save")
                                    .font(TrimDesignSystem.Typography.subheader)
                                    .foregroundColor(TrimDesignSystem.Colors.background)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(TrimDesignSystem.Colors.accentPrimary)
                                    .cornerRadius(TrimDesignSystem.Radius.medium)
                            }
                            .trimPressAnimation()
                            
                            Button(action: onComplete) {
                                Text("Continue")
                                    .font(TrimDesignSystem.Typography.body)
                                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            }
                            .trimPressAnimation()
                        }
                        .padding(.horizontal, TrimDesignSystem.Spacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(height: 120)
            }
            .padding(.vertical, TrimDesignSystem.Spacing.xl)
        }
        .onAppear {
            startCinematicSequence()
        }
    }
    
    private func startCinematicSequence() {
        // 0-2s: Fade in logo
        withAnimation(.easeIn(duration: 1.0)) {
            phase = .logo
        }
        
        // 2-5s: Scanning animation starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                phase = .scanning
            }
            
            // Text sequence
            withAnimation(.easeInOut(duration: 0.5)) { scanText = "Analyzing patterns..." }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) { scanText = "Detecting subscriptions..." }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) { scanText = "Finding savings..." }
            }
            
            // Progress sequence (smooth over 3 seconds)
            withAnimation(.easeInOut(duration: 3.0)) {
                scanProgress = 1.0
            }
        }
        
        // 5-8s: Result lock
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                phase = .result
            }
        }
        
        // 8-10s: CTA appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                phase = .cta
            }
        }
    }
}
