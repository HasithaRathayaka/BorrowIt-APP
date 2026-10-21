import SwiftUI

// MARK: - Screen 1: Welcome & Onboarding
public struct WelcomeOnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var settings: AppSettingsManager
    @State private var emailText: String = "alex@icloud.com"
    @State private var isShowingEmailInput: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                // Emerald App Logo Badge
                ZStack {
                    Circle()
                        .fill(Color.softMintTint)
                        .frame(width: 96, height: 96)
                    
                    Image(systemName: "hand.raised.square.on.square.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                }
                .shadow(color: Color.brandEmerald.opacity(0.15), radius: 16, y: 6)
                
                // Headline & Tagline
                VStack(spacing: 10) {
                    Text("Borrow nearby.\nOwn less. Know more neighbors.")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                    
                    Text("Join Cedar Grove in sharing power tools, camping gear, and appliances. Save money, cut waste, and verify handoffs in seconds.")
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 28)
                        .lineSpacing(3)
                }
                
                // Feature Highlights
                VStack(spacing: 14) {
                    FeatureBulletRow(
                        icon: "faceid",
                        title: "Biometric Protection",
                        subtitle: "Approvals & addresses gated behind Face ID"
                    )
                    FeatureBulletRow(
                        icon: "location.circle.fill",
                        title: "50m Geofenced Handoffs",
                        subtitle: "Offline QR pass activates within 50m of pickup spot"
                    )
                    FeatureBulletRow(
                        icon: "leaf.circle.fill",
                        title: "Zero Waste Neighborhood",
                        subtitle: "Over 42 kg of landfill waste avoided this year"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .squircleCard()
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Auth Actions
                VStack(spacing: 12) {
                    // Sign in with Apple Button
                    Button(action: {
                        Task {
                            await authVM.signInWithApple()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Sign in with Apple")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .accessibilityLabel("Sign in with Apple")
                    
                    // Continue with Email (Supabase Auth)
                    Button(action: {
                        Task {
                            await authVM.signInWithEmail(email: emailText)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Continue with Email (Supabase)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .accessibilityLabel("Continue with Email using Supabase Authentication")
                    
                    Text("By continuing, you agree to BorrowIt Community Safety & Deposit Hold Terms.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .liveAccessibilityScale()
    }
}

// MARK: - Feature Bullet Row Helper
struct FeatureBulletRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
