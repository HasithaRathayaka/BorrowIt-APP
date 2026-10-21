import SwiftUI
import Charts

// MARK: - Screen 15: User Profile & Swift Charts Stats
public struct ProfileStatsView: View {
    @EnvironmentObject var settings: AppSettingsManager
    public var profile: UserProfile = .currentUser
    
    public init(profile: UserProfile = .currentUser) {
        self.profile = profile
    }
    
    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Profile Header Box
                        VStack(spacing: 12) {
                            Circle()
                                .fill(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                .frame(width: 76, height: 76)
                                .overlay(
                                    Text(profile.initials)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.brandEmerald.opacity(0.2), radius: 10, y: 4)
                            
                            VStack(spacing: 4) {
                                Text(profile.name)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("\(profile.neighborhood) · \(profile.memberSince)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Verification and Activity Pills
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                        .font(.system(size: 12))
                                    Text("ID verified")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.softMintTint)
                                .clipShape(Capsule())
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "shippingbox.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 11))
                                    Text("\(profile.totalBorrows) borrows")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 16)
                        
                        // 2. Metric Cards (Trust Score & Community Rating)
                        HStack(spacing: 12) {
                            // Trust Score Card
                            VStack(alignment: .leading, spacing: 6) {
                                Text("TRUST SCORE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text("\(profile.trustScore)")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                    Text("/ 100")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(profile.trustScoreSubtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .squircleCard()
                            
                            // Community Rating Card
                            VStack(alignment: .leading, spacing: 6) {
                                Text("COMMUNITY RATING")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Text(String(format: "%.1f", profile.communityRating))
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 18))
                                }
                                
                                Text("from \(profile.reviewCount) neighbors")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .squircleCard()
                        }
                        .padding(.horizontal, 20)
                        
                        // 3. Swift Charts Savings Bar Chart Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SAVINGS · SWIFT CHARTS")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Text("$\(Int(profile.totalMoneySaved)) saved vs. buying")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 20))
                                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                            }
                            
                            // Swift Charts BarMark 6-Month Chart
                            Chart(profile.monthlySavings) { item in
                                BarMark(
                                    x: .value("Month", item.month),
                                    y: .value("Saved ($)", item.amountSaved)
                                )
                                .foregroundStyle(
                                    item.isCurrentMonth ?
                                    ThemeColors.emerald(highContrast: settings.highContrastEnabled) :
                                    Color.secondary.opacity(0.35)
                                )
                                .cornerRadius(6)
                                .annotation(position: .top, spacing: 4) {
                                    Text("$\(Int(item.amountSaved))")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(item.isCurrentMonth ? ThemeColors.emerald(highContrast: settings.highContrastEnabled) : .secondary)
                                }
                            }
                            .frame(height: 180)
                            .chartYAxis(.hidden)
                            .chartXAxis {
                                AxisMarks(values: .automatic) { _ in
                                    AxisValueLabel()
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                            }
                        }
                        .padding(18)
                        .squircleCard()
                        .padding(.horizontal, 20)
                        
                        // 4. Two Sustainability Impact Cards
                        HStack(spacing: 12) {
                            // Waste Avoided
                            HStack(spacing: 12) {
                                Image(systemName: "leaf.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(Int(profile.wasteAvoidedKg)) kg")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("waste avoided")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .squircleCard()
                            
                            // Neighbors Lent
                            HStack(spacing: 12) {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(profile.totalLends)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("neighbors lent")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .squircleCard()
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Profile & Stats")
        .navigationBarTitleDisplayMode(.inline)
        .liveAccessibilityScale()
    }
}
