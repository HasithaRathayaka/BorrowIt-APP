import SwiftUI
import UIKit

// MARK: - Screen 17: Settings, Accessibility & Viva Demo Toolkit
public struct SettingsView: View {
    @EnvironmentObject var settings: AppSettingsManager
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var lifecycleVM: BorrowLifecycleViewModel
    
    @State private var navigateToProfile: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Demo Toast Banner if present
                            if let toast = settings.demoBannerMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.brandEmerald)
                                    Text(toast)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.softMintTint)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // 1. Tappable Profile Summary Card
                            Button(action: {
                                navigateToProfile = true
                            }) {
                                HStack(spacing: 14) {
                                    Group {
                                        if let data = authVM.currentUser.avatarImageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 56, height: 56)
                                                .clipShape(Circle())
                                        } else if let urlStr = authVM.currentUser.avatarImageURL, let url = URL(string: urlStr) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let img):
                                                    img
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 56, height: 56)
                                                        .clipShape(Circle())
                                                default:
                                                    defaultInitialsBadge
                                                }
                                            }
                                        } else {
                                            defaultInitialsBadge
                                        }
                                    }
                                    .shadow(color: Color.brandEmerald.opacity(0.15), radius: 6, y: 3)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(authVM.currentUser.name)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text(authVM.currentUser.email)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                        Text("\(authVM.currentUser.neighborhood) · Trust Score \(authVM.currentUser.trustScore)/100")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(16)
                                .squircleCard()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // 2. The 6 Functional Rubric Toggles
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PLATFORM & ACCESSIBILITY CONTROLS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 14) {
                                    // 1. Notifications Toggle
                                    Toggle(isOn: $settings.notificationsEnabled) {
                                        SettingsToggleRow(
                                            icon: "bell.fill",
                                            iconColor: .orange,
                                            title: "Notifications",
                                            subtitle: "Requests, messages, and pickup due reminders"
                                        )
                                    }
                                    .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                    
                                    Divider()
                                    
                                    // 2. Face ID Security Toggle
                                    Toggle(isOn: $settings.faceIDLockEnabled) {
                                        SettingsToggleRow(
                                            icon: "faceid",
                                            iconColor: ThemeColors.emerald(highContrast: settings.highContrastEnabled),
                                            title: "Face ID Protection",
                                            subtitle: "Lock app on exit and gate borrow approvals"
                                        )
                                    }
                                    .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                    
                                    Divider()
                                    
                                    // 3. VoiceOver Assist Toggle
                                    Toggle(isOn: $settings.voiceOverAssistEnabled) {
                                        SettingsToggleRow(
                                            icon: "waveform.and.person.filled",
                                            iconColor: .blue,
                                            title: "VoiceOver Assistance",
                                            subtitle: "Enriched accessibility descriptions & reading order"
                                        )
                                    }
                                    .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                    
                                    Divider()
                                    
                                    // 4. Dynamic Type Scale Stepper / Multiplier
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            SettingsToggleRow(
                                                icon: "textformat.size",
                                                iconColor: .purple,
                                                title: "Dynamic Type Scaling",
                                                subtitle: "Interactive UI text scale: \(String(format: "%.1fx", settings.dynamicTypeScale))"
                                            )
                                            Spacer()
                                            HStack(spacing: 12) {
                                                Button(action: {
                                                    if settings.dynamicTypeScale > 0.85 {
                                                        settings.dynamicTypeScale -= 0.1
                                                    }
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                                }
                                                Button(action: {
                                                    if settings.dynamicTypeScale < 1.35 {
                                                        settings.dynamicTypeScale += 0.1
                                                    }
                                                }) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                                }
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // 5. Reduce Motion Toggle
                                    Toggle(isOn: $settings.reduceMotionEnabled) {
                                        SettingsToggleRow(
                                            icon: "figure.walk.motion",
                                            iconColor: .indigo,
                                            title: "Reduce Motion",
                                            subtitle: "Disables spring and slide animations across all screens"
                                        )
                                    }
                                    .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                    
                                    Divider()
                                    
                                    // 6. High Contrast Toggle
                                    Toggle(isOn: $settings.highContrastEnabled) {
                                        SettingsToggleRow(
                                            icon: "circle.lefthalf.filled",
                                            iconColor: .pink,
                                            title: "Increase Contrast",
                                            subtitle: "Enhances borders, darker emerald, and high-visibility text"
                                        )
                                    }
                                    .tint(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                }
                            }
                            .padding(18)
                            .squircleCard()
                            .padding(.horizontal, 20)
                            
                            // 3. Privacy Banner
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                
                                Text("Precise location and official ID verification details are encrypted and never revealed to the neighborhood.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(2)
                            }
                            .padding(14)
                            .squircleCard()
                            .padding(.horizontal, 20)

                            
                            // 4. Account Actions
                            VStack(spacing: 12) {
                                Button(action: {
                                    authVM.signOut()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Log Out")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                        Spacer()
                                    }
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileStatsView(profile: authVM.currentUser)
            }
        }
        .liveAccessibilityScale()
    }
    
    private var defaultInitialsBadge: some View {
        Circle()
            .fill(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
            .frame(width: 56, height: 56)
            .overlay(
                Text(authVM.currentUser.initials)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Settings Row Helpers
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 26)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct DemoToolkitButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @EnvironmentObject var settings: AppSettingsManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                    .frame(width: 22)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
