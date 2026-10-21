import SwiftUI

// MARK: - Screen 16: Designed Empty & Error States
public struct EmptyExploreStateView: View {
    @EnvironmentObject var exploreVM: ExploreViewModel
    @EnvironmentObject var settings: AppSettingsManager
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Location Off Graphic Illustration Box
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 96, height: 96)
                
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 42))
                    .foregroundColor(.secondary)
            }
            
            // Texts
            VStack(spacing: 8) {
                Text("No Nearby Items")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Nothing is available within \(Int(exploreVM.searchRadiusMeters))m right now. Try again soon or expand your radius to see more neighbors.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .lineSpacing(3)
            }
            
            // Quick Suggestion Chips
            HStack(spacing: 8) {
                Button(action: {
                    exploreVM.expandRadiusTo1000m()
                    if settings.simulateEmptyState {
                        settings.simulateEmptyState = false
                    }
                }) {
                    Text("Try 1 km")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.softMintTint)
                        .clipShape(Capsule())
                }
                
                Button(action: {
                    exploreVM.resetFilters()
                    if settings.simulateEmptyState {
                        settings.simulateEmptyState = false
                    }
                }) {
                    Text("Clear categories")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    exploreVM.expandRadiusTo1000m()
                    if settings.simulateEmptyState {
                        settings.simulateEmptyState = false
                    }
                }) {
                    Text("Expand to 1 km")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .buttonStyle(BrandEmeraldButtonStyle())
                
                Button(action: {
                    exploreVM.resetFilters()
                    if settings.simulateEmptyState {
                        settings.simulateEmptyState = false
                    }
                    Task {
                        await exploreVM.fetchItems()
                    }
                }) {
                    Text("Retry nearby search")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liveAccessibilityScale()
    }
}
