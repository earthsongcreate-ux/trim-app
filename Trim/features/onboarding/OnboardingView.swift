import SwiftUI
import UIKit

enum OnboardingStep: Hashable {
    case welcome
    case goal
    case obstacle
    case firstName
    case personalization
    case routine
    case planPreview
    case bankConnection
    case liveScan
    case insight
    case paywall
}

struct OnboardingView: View {
    let onFinished: (_ firstName: String?, _ monthlyIncome: Int, _ monthlySavingsGoal: Int) -> Void
    
    private enum FocusField: Hashable {
        case firstName
        case monthlyIncome
        case monthlySavingsGoal
    }
    
    @FocusState private var focusedField: FocusField?
    
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var scanProgress: CGFloat = 0.0
    @State private var isScanning = false
    @State private var selectedGoal: String? = nil
    @State private var selectedObstacle: String? = nil
    @State private var selectedRoutine: String? = nil
    @State private var firstName: String = ""
    @State private var monthlyIncomeText: String = ""
    @State private var monthlySavingsGoalText: String = ""
    @State private var hasInvalidHapticFired: Bool = false
    @State private var transitionDirectionIsForward: Bool = true
    
    var body: some View {
        ZStack {
            TrimDesignSystem.Colors.background.ignoresSafeArea()
            RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.03), Color.clear]), center: .center, startRadius: 0, endRadius: 500)
                .ignoresSafeArea()
            
            VStack {
                currentStepView
                    .id(currentStep)
                    .transition(stepTransition)
            }
            .padding(TrimDesignSystem.Spacing.m)
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
    
    private var progressStep: Int? {
        switch currentStep {
        case .welcome: return 1
        case .goal: return 2
        case .obstacle: return 3
        case .firstName: return 4
        case .personalization: return 5
        case .routine: return 6
        case .planPreview: return 7
        case .bankConnection: return 8
        case .liveScan: return 9
        case .insight: return 10
        case .paywall: return 11
        }
    }
    
    private var progressTotal: Int { 11 }
    
    private var progressFraction: CGFloat {
        guard let step = progressStep else { return 0 }
        return CGFloat(step) / CGFloat(progressTotal)
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcome:
            welcomeStep
        case .goal:
            goalStep
        case .obstacle:
            obstacleStep
        case .firstName:
            firstNameStep
        case .personalization:
            personalizationStep
        case .routine:
            routineStep
        case .planPreview:
            planPreviewStep
        case .bankConnection:
            bankConnectionStep
        case .liveScan:
            liveScanStep
        case .insight:
            insightStep
        case .paywall:
            paywallStep
        }
    }
    
    private var stepTransition: AnyTransition {
        let insertionEdge: Edge = transitionDirectionIsForward ? .trailing : .leading
        let removalEdge: Edge = transitionDirectionIsForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }
    
    private var canGoBack: Bool {
        switch currentStep {
        case .welcome:
            return false
        case .liveScan:
            return !isScanning
        default:
            return true
        }
    }
    
    private func goBack() {
        focusedField = nil
        switch currentStep {
        case .welcome:
            break
        case .goal:
            setStep(.welcome)
        case .obstacle:
            setStep(.goal)
        case .firstName:
            setStep(.obstacle)
        case .personalization:
            setStep(.firstName)
        case .routine:
            setStep(.personalization)
        case .planPreview:
            setStep(.routine)
        case .bankConnection:
            setStep(.planPreview)
        case .liveScan:
            setStep(.bankConnection)
        case .insight:
            setStep(.liveScan)
        case .paywall:
            setStep(.insight)
        }
    }
    
    private func stepOrder(_ step: OnboardingStep) -> Int {
        switch step {
        case .welcome: return 1
        case .goal: return 2
        case .obstacle: return 3
        case .firstName: return 4
        case .personalization: return 5
        case .routine: return 6
        case .planPreview: return 7
        case .bankConnection: return 8
        case .liveScan: return 9
        case .insight: return 10
        case .paywall: return 11
        }
    }
    
    private func setStep(_ next: OnboardingStep) {
        transitionDirectionIsForward = stepOrder(next) >= stepOrder(currentStep)
        currentStep = next
    }
    
    private func stepHeader(title: String) -> some View {
        VStack(spacing: TrimDesignSystem.Spacing.s) {
            HStack {
                Button(action: { goBack() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
                .trimPressAnimation()
                .opacity(canGoBack ? 1 : 0)
                .disabled(!canGoBack)
                
                Spacer()
                
                if let step = progressStep {
                    Text("Step \(step) of \(progressTotal)")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
            }
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(TrimDesignSystem.Colors.accentPrimary)
                        .frame(width: max(0, min(proxy.size.width, proxy.size.width * progressFraction)))
                }
            }
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.25), value: progressFraction)
            
            Text(title)
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            HStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("TRIM")
                    .font(.system(size: 32, weight: .heavy, design: .default))
                    .kerning(1.5)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
            
            Text("Smarter money in minutes.")
                .font(TrimDesignSystem.Typography.header)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Answer a few quick questions. We’ll tailor your plan.")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: { setStep(.goal) }) {
                Text("Get Started")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
        }
    }

    private var goalStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            stepHeader(title: "What do you want first?")
            
            VStack(spacing: TrimDesignSystem.Spacing.m) {
                optionCard(title: "Cancel unused subscriptions", icon: "xmark.circle", selection: $selectedGoal)
                optionCard(title: "Lower recurring bills", icon: "arrow.down.circle", selection: $selectedGoal)
                optionCard(title: "Track spending automatically", icon: "chart.pie", selection: $selectedGoal)
                optionCard(title: "Just exploring", icon: "sparkles", selection: $selectedGoal)
            }
            
            Spacer()
            
            Button(action: { setStep(.obstacle) }) {
                Text("Continue")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
            .disabled(selectedGoal == nil)
            .opacity(selectedGoal == nil ? 0.6 : 1.0)
        }
    }
    
    private func optionCard(title: String, icon: String, selection: Binding<String?>) -> some View {
        let isSelected = selection.wrappedValue == title
        return Button(action: { selection.wrappedValue = title }) {
            PremiumGlassCard(.inset) {
                HStack(spacing: TrimDesignSystem.Spacing.m) {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? TrimDesignSystem.Colors.accentSecondary : TrimDesignSystem.Colors.textPrimary)
                        .frame(width: 28)
                    
                    Text(title)
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? TrimDesignSystem.Colors.accentSecondary : Color.white.opacity(0.18))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isSelected ? TrimDesignSystem.Colors.accentSecondary.opacity(0.55) : Color.white.opacity(0.06),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: Color.black.opacity(isSelected ? 0.35 : 0.15), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 10 : 6)
        .trimPressAnimation()
    }
    
    private var obstacleStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            stepHeader(title: "What’s been hardest?")
            
            VStack(spacing: TrimDesignSystem.Spacing.m) {
                optionCard(title: "Too many subscriptions", icon: "rectangle.stack.badge.minus", selection: $selectedObstacle)
                optionCard(title: "Bills keep increasing", icon: "arrow.up.right.circle", selection: $selectedObstacle)
                optionCard(title: "Hard to stay consistent", icon: "clock.arrow.circlepath", selection: $selectedObstacle)
                optionCard(title: "Not sure yet", icon: "questionmark.circle", selection: $selectedObstacle)
            }
            
            Spacer()
            
            Button(action: { setStep(.firstName) }) {
                Text("Continue")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
            .disabled(selectedObstacle == nil)
            .opacity(selectedObstacle == nil ? 0.6 : 1.0)
        }
    }
    
    private var firstNameStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            stepHeader(title: "What should we call you?")
            
            PremiumGlassCard(.inset) {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.s) {
                    Text("First name (optional)")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    
                    TextField("First name", text: $firstName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .firstName)
                        .padding()
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(TrimDesignSystem.Radius.medium)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                }
            }
            
            Spacer()
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Button(action: {
                    focusedField = nil
                    setStep(.personalization)
                }) {
                    Text("Continue")
                        .font(TrimDesignSystem.Typography.subheader)
                        .foregroundColor(TrimDesignSystem.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(TrimDesignSystem.Colors.accentPrimary)
                        .cornerRadius(TrimDesignSystem.Radius.medium)
                }
                .trimPressAnimation()
                
                Button(action: {
                    focusedField = nil
                    firstName = ""
                    setStep(.personalization)
                }) {
                    Text("Skip")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .trimPressAnimation()
            }
        }
    }
    
    private var personalizationStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            stepHeader(title: "A quick money check")
            
            PremiumGlassCard(.inset) {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                    moneyField(title: "Monthly income", text: $monthlyIncomeText)
                        .focused($focusedField, equals: .monthlyIncome)
                        .onChange(of: monthlyIncomeText) { _, newValue in
                            let formatted = formatNumberInput(newValue)
                            if formatted != monthlyIncomeText { monthlyIncomeText = formatted }
                            handleValidationHaptics()
                        }
                    
                    quickPickSection(
                        title: "Quick picks",
                        values: [3000, 5000, 10000, 15000],
                        onPick: { value in
                            focusedField = nil
                            monthlyIncomeText = formatNumberInput(String(value))
                            handleValidationHaptics()
                        }
                    )
                    
                    moneyField(title: "Monthly savings goal", text: $monthlySavingsGoalText)
                        .focused($focusedField, equals: .monthlySavingsGoal)
                        .onChange(of: monthlySavingsGoalText) { _, newValue in
                            let formatted = formatNumberInput(newValue)
                            if formatted != monthlySavingsGoalText { monthlySavingsGoalText = formatted }
                            handleValidationHaptics()
                        }
                    
                    if let message = personalizationValidationMessage {
                        Text(message)
                            .font(TrimDesignSystem.Typography.caption)
                            .foregroundColor(Color.red.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let message = savingsGoalPercentMessage {
                        Text(message)
                            .font(TrimDesignSystem.Typography.caption)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Optional — you can change this anytime.")
                            .font(TrimDesignSystem.Typography.caption)
                            .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    quickPickSection(
                        title: "Quick picks",
                        values: [200, 500, 1000, 2000],
                        onPick: { value in
                            focusedField = nil
                            monthlySavingsGoalText = formatNumberInput(String(value))
                            handleValidationHaptics()
                        }
                    )
                }
            }
            
            Spacer()
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Button(action: {
                    focusedField = nil
                    setStep(.routine)
                }) {
                    Text("Continue")
                        .font(TrimDesignSystem.Typography.subheader)
                        .foregroundColor(TrimDesignSystem.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(TrimDesignSystem.Colors.accentPrimary)
                        .cornerRadius(TrimDesignSystem.Radius.medium)
                }
                .trimPressAnimation()
                .disabled(personalizationValidationMessage != nil)
                .opacity(personalizationValidationMessage != nil ? 0.6 : 1.0)
                
                Button(action: {
                    focusedField = nil
                    monthlyIncomeText = ""
                    monthlySavingsGoalText = ""
                    setStep(.routine)
                }) {
                    Text("Skip for now")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .trimPressAnimation()
            }
        }
    }
    
    private var routineStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            stepHeader(title: "How often should we check in?")
            
            VStack(spacing: TrimDesignSystem.Spacing.m) {
                optionCard(title: "Daily (2 min)", icon: "sun.max", selection: $selectedRoutine)
                optionCard(title: "3× / week", icon: "calendar.badge.clock", selection: $selectedRoutine)
                optionCard(title: "Weekly", icon: "calendar", selection: $selectedRoutine)
                optionCard(title: "I’ll decide later", icon: "ellipsis.circle", selection: $selectedRoutine)
            }
            
            Spacer()
            
            Button(action: { setStep(.planPreview) }) {
                Text("Continue")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
            .disabled(selectedRoutine == nil)
            .opacity(selectedRoutine == nil ? 0.6 : 1.0)
        }
    }
    
    private var planPreviewStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.l) {
            stepHeader(title: "Here’s your plan")
            
            PremiumGlassCard {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                    Text("Based on your answers:")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        planBullet(text: planBullets[0])
                        planBullet(text: planBullets[1])
                        planBullet(text: planBullets[2])
                    }
                }
            }
            
            Spacer()
            
            Button(action: { setStep(.bankConnection) }) {
                Text("Start secure scan")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
        }
    }
    
    private var planBullets: [String] {
        var bullets: [String] = []
        
        if let goal = selectedGoal?.lowercased() {
            if goal.contains("subscription") {
                bullets.append("Flag unused subscriptions worth canceling")
            } else if goal.contains("bills") {
                bullets.append("Spot recurring bills that can be negotiated")
            } else if goal.contains("spending") {
                bullets.append("Categorize spend and highlight drift")
            } else {
                bullets.append("Surface the biggest savings opportunities")
            }
        } else {
            bullets.append("Surface the biggest savings opportunities")
        }
        
        if let obstacle = selectedObstacle?.lowercased() {
            if obstacle.contains("consistent") {
                bullets.append("Turn insights into a simple routine that sticks")
            } else if obstacle.contains("increasing") {
                bullets.append("Catch increases early before they compound")
            } else {
                bullets.append("Make your next action obvious and easy")
            }
        } else {
            bullets.append("Make your next action obvious and easy")
        }
        
        if let routine = selectedRoutine {
            bullets.append("Check-in cadence: \(routine)")
        } else {
            bullets.append("Set a check-in cadence you can maintain")
        }
        
        return bullets
    }
    
    private func planBullet(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(TrimDesignSystem.Colors.accentSecondary.opacity(0.9))
                .frame(width: 6, height: 6)
                .padding(.top, 7)
            Text(text)
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
        }
    }
    
    // MARK: - 3. Bank Connection Step
    private var bankConnectionStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Secure Bank Connection")
                    .font(TrimDesignSystem.Typography.header)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                
                Text("Trim uses Plaid for secure, read-only access. We never store your bank login.")
                    .font(TrimDesignSystem.Typography.body)
                    .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            PremiumGlassCard(.inset) {
                VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.m) {
                    trustRow(icon: "checkmark.circle.fill", text: "256-bit encryption")
                    trustRow(icon: "checkmark.circle.fill", text: "Read-only access")
                    trustRow(icon: "checkmark.circle.fill", text: "Disconnect anytime")
                }
            }
            
            Spacer()
            
            Button(action: {
                scanProgress = 0
                setStep(.liveScan)
                simulateScan()
            }) {
                Text("Connect Securely")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
        }
    }
    
    private func trustRow(icon: String, text: String) -> some View {
        HStack(spacing: TrimDesignSystem.Spacing.m) {
            Image(systemName: icon)
                .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
            Text(text)
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
        }
    }
    
    // MARK: - 4. Live Scan Step
    private var liveScanStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            ZStack {
                // Base track
                Circle()
                    .stroke(Color.black.opacity(0.4), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .shadow(color: .black.opacity(0.6), radius: 6, x: 4, y: 4)
                    .shadow(color: .white.opacity(0.05), radius: 2, x: -1, y: -1)
                
                // Active stroke
                Circle()
                    .trim(from: 0, to: scanProgress)
                    .stroke(TrimDesignSystem.Colors.accentPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 2, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .trim(from: max(0, scanProgress - 0.02), to: scanProgress)
                            .stroke(TrimDesignSystem.Colors.edgePrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    )
                
                VStack(spacing: TrimDesignSystem.Spacing.xs) {
                    Text("\(Int(scanProgress * 100))%")
                        .font(TrimDesignSystem.Typography.header)
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                    Text("Scanning...")
                        .font(TrimDesignSystem.Typography.caption)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding(TrimDesignSystem.Spacing.l)
            .background(
                RadialGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.1)]), center: .center, startRadius: 0, endRadius: 100)
            )
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.black.opacity(0.7), lineWidth: 8)
                    .blur(radius: 6)
                    .offset(x: 6, y: 6)
                    .mask(RoundedRectangle(cornerRadius: 100).fill(LinearGradient(gradient: Gradient(colors: [Color.black, Color.clear]), startPoint: .topLeading, endPoint: .bottomTrailing)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.white.opacity(0.08), lineWidth: 2)
                    .blur(radius: 2)
                    .offset(x: -1, y: -1)
                    .mask(RoundedRectangle(cornerRadius: 100).fill(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)))
            )
            
            Text("Analyzing 3,241 transactions...")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    private func simulateScan() {
        isScanning = true
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.linear(duration: 0.05)) {
                scanProgress += 0.02
            }
            if scanProgress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isScanning = false
                    setStep(.insight)
                }
            }
        }
    }
    
    // MARK: - 5. Insight Step
    private var insightStep: some View {
        VStack(spacing: TrimDesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: TrimDesignSystem.Spacing.s) {
                Text("Scan Complete")
                    .font(TrimDesignSystem.Typography.caption)
                    .foregroundColor(TrimDesignSystem.Colors.accentPrimary)
                    .kerning(1.0)
                
                Text("We found money to save.")
                    .font(TrimDesignSystem.Typography.header)
                    .foregroundColor(TrimDesignSystem.Colors.textPrimary)
            }
            
            PremiumGlassCard {
                VStack(spacing: TrimDesignSystem.Spacing.l) {
                    Text("$842")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                        .shadow(color: TrimDesignSystem.Colors.glowPrimary, radius: 4, x: 0, y: 0)
                    
                    Text("in annual savings across unused subscriptions and negotiable bills.")
                        .font(TrimDesignSystem.Typography.body)
                        .foregroundColor(TrimDesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            Button(action: { setStep(.paywall) }) {
                Text("Unlock full details")
                    .font(TrimDesignSystem.Typography.subheader)
                    .foregroundColor(TrimDesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TrimDesignSystem.Colors.accentPrimary)
                    .cornerRadius(TrimDesignSystem.Radius.medium)
            }
            .trimPressAnimation()
        }
    }
    
    // MARK: - 6. Paywall Step
    private var paywallStep: some View {
        PaywallView(
            paywallData: PaywallData(
                type: "soft",
                triggerReason: "onboarding",
                content: PaywallContent(
                    headline: "Try Premium — $0 today",
                    subtext: "Try everything free for 7 days. Cancel anytime.",
                    pricing: PaywallPricing(monthly: 12.99, annual: 99.0, trialDays: 7),
                    primaryCta: "Start 7-day free trial",
                    secondaryCta: "Not now"
                )
            ),
            onDismiss: {
                onFinished(cleanFirstName(), parseAmount(monthlyIncomeText), parseAmount(monthlySavingsGoalText))
            },
            onConvert: {
                onFinished(cleanFirstName(), parseAmount(monthlyIncomeText), parseAmount(monthlySavingsGoalText))
            }
        )
    }
    
    private var personalizationValidationMessage: String? {
        let income = parseAmount(monthlyIncomeText)
        let goal = parseAmount(monthlySavingsGoalText)
        if income > 0 && goal > income {
            return "Savings goal can’t exceed income."
        }
        return nil
    }
    
    private var savingsGoalPercentMessage: String? {
        let income = parseAmount(monthlyIncomeText)
        let goal = parseAmount(monthlySavingsGoalText)
        guard income > 0, goal > 0 else { return nil }
        let ratio = min(max(Double(goal) / Double(income), 0), 1)
        let percent = Int((ratio * 100).rounded())
        return "That’s about \(percent)% of your monthly income."
    }
    
    private func moneyField(title: String, text: Binding<String>) -> some View {
        HStack(spacing: TrimDesignSystem.Spacing.s) {
            Text("$")
                .font(TrimDesignSystem.Typography.body)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            TextField("\(title) (optional)", text: text)
                .keyboardType(.numberPad)
                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
        }
        .padding()
        .background(Color.black.opacity(0.25))
        .cornerRadius(TrimDesignSystem.Radius.medium)
    }
    
    private func quickPickSection(title: String, values: [Int], onPick: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: TrimDesignSystem.Spacing.xs) {
            Text(title)
                .font(TrimDesignSystem.Typography.caption)
                .foregroundColor(TrimDesignSystem.Colors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TrimDesignSystem.Spacing.s) {
                    ForEach(values, id: \.self) { value in
                        Button(action: { onPick(value) }) {
                            Text("$\(formatNumberInput(String(value)))")
                                .font(TrimDesignSystem.Typography.caption)
                                .foregroundColor(TrimDesignSystem.Colors.textPrimary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.25))
                                .cornerRadius(TrimDesignSystem.Radius.medium)
                        }
                        .trimPressAnimation()
                    }
                }
            }
        }
    }
    
    private func cleanFirstName() -> String? {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private func formatNumberInput(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }
        let value = Int(digits) ?? 0
        return Self.decimalFormatter.string(from: NSNumber(value: value)) ?? ""
    }
    
    private func parseAmount(_ raw: String) -> Int {
        let digits = raw.filter { $0.isNumber }
        return Int(digits) ?? 0
    }
    
    private func handleValidationHaptics() {
        let income = parseAmount(monthlyIncomeText)
        let goal = parseAmount(monthlySavingsGoalText)
        let isInvalid = income > 0 && goal > income
        if isInvalid && !hasInvalidHapticFired {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            hasInvalidHapticFired = true
        } else if !isInvalid {
            hasInvalidHapticFired = false
        }
    }
}
