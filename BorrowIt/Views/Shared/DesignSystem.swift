import SwiftUI

// MARK: - Color Palette Extensions
public extension Color {
    // Brand Emerald
    static let brandEmerald = Color(hex: "#10B981")
    static let brandEmeraldDark = Color(hex: "#34D399")
    static let brandEmeraldHighContrast = Color(hex: "#047857")
    
    // Mint Surface Tint
    static let softMintTint = Color(hex: "#ECFDF5")
    
    // Dark Navy
    static let darkNavyPass = Color(hex: "#0F172A")
    
    // Status Semantics
    static let statusAmberText = Color(hex: "#D97706")
    static let statusAmberBg = Color(hex: "#FEF3C7")
    
    static let statusBlueText = Color(hex: "#2563EB")
    static let statusBlueBg = Color(hex: "#DBEAFE")
    
    static let statusEmeraldText = Color(hex: "#059669")
    static let statusEmeraldBg = Color(hex: "#D1FAE5")
    
    static let statusSlateText = Color(hex: "#475569")
    static let statusSlateBg = Color(hex: "#F1F5F9")
    
    // Hex Initializer
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 16, 185, 129)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Dynamic Theme Helper
public struct ThemeColors {
    public static func emerald(highContrast: Bool) -> Color {
        highContrast ? .brandEmeraldHighContrast : .brandEmerald
    }
}

// MARK: - Card Container Squircle Modifier
public struct SquircleCardModifier: ViewModifier {
    @EnvironmentObject var settings: AppSettingsManager
    public var cornerRadius: CGFloat = 20
    public var backgroundColor: Color = Color(uiColor: .secondarySystemGroupedBackground)
    
    public func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        settings.highContrastEnabled ? Color.primary.opacity(0.3) : Color.primary.opacity(0.06),
                        lineWidth: settings.highContrastEnabled ? 2.0 : 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(settings.highContrastEnabled ? 0.12 : 0.04),
                radius: settings.highContrastEnabled ? 14 : 8,
                x: 0,
                y: 3
            )
    }
}

public extension View {
    func squircleCard(cornerRadius: CGFloat = 20, backgroundColor: Color = Color(uiColor: .secondarySystemGroupedBackground)) -> some View {
        modifier(SquircleCardModifier(cornerRadius: cornerRadius, backgroundColor: backgroundColor))
    }
}

// MARK: - Live Dynamic Type Scale Modifier
public struct DynamicTypeScaledModifier: ViewModifier {
    @EnvironmentObject var settings: AppSettingsManager
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(settings.dynamicTypeScale)
    }
}

public extension View {
    func liveAccessibilityScale() -> some View {
        modifier(DynamicTypeScaledModifier())
    }
}

// MARK: - Reusable Status Badges & Pills
public struct BorrowStatusPill: View {
    public var state: BorrowState
    @EnvironmentObject var settings: AppSettingsManager
    
    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: state.pillColorHex))
                .frame(width: 6, height: 6)
            
            Text(state.shortBadge)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: state.pillColorHex))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(hex: state.pillBackgroundHex))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(state.displayTitle)")
    }
}

// MARK: - Core ML Badge
public struct CoreMLBadge: View {
    public var tag: String
    public var confidence: Double
    @EnvironmentObject var settings: AppSettingsManager
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
            
            Text("Core ML: \(tag)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Material.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(0.35), lineWidth: 1)
        )
        .accessibilityLabel("Auto-categorized by Core ML as \(tag), confidence \(Int(confidence * 100)) percent")
    }
}

// MARK: - Interactive Star Rating Row
public struct RatingStarRow: View {
    public var rating: Double
    public var maxRating: Int = 5
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: Double(index) <= rating ? "star.fill" : (Double(index) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.orange)
            }
            Text(String(format: "%.1f", rating))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .fixedSize()
        }
        .fixedSize()
        .accessibilityLabel("\(String(format: "%.1f", rating)) stars out of \(maxRating)")
    }
}

// MARK: - Primary Button Style
public struct BrandEmeraldButtonStyle: ButtonStyle {
    @EnvironmentObject var settings: AppSettingsManager
    public var isFullWidth: Bool = true
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 15)
            .padding(.horizontal, 24)
            .background(ThemeColors.emerald(highContrast: settings.highContrastEnabled))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed && !settings.reduceMotionEnabled ? 0.98 : 1.0)
            .shadow(
                color: ThemeColors.emerald(highContrast: settings.highContrastEnabled).opacity(configuration.isPressed ? 0.15 : 0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .animation(settings.reduceMotionEnabled ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Realistic Item Photo View with AsyncImage & Modern Visuals
public struct ItemPhotoView: View {
    public let item: BorrowItem
    public var height: CGFloat = 160
    public var cornerRadius: CGFloat = 16
    
    public init(item: BorrowItem, height: CGFloat = 160, cornerRadius: CGFloat = 16) {
        self.item = item
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    // Resolve UIImage from Base64 Data URL, Local File Path, or Documents directory
    private var localOrBase64Image: UIImage? {
        guard let urlString = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines), !urlString.isEmpty else {
            return nil
        }
        
        // 1. Base64 Data URI: "data:image/...;base64,...."
        if urlString.starts(with: "data:image") {
            let parts = urlString.components(separatedBy: ",")
            if let base64Str = parts.last,
               let data = Data(base64Encoded: base64Str, options: .ignoreUnknownCharacters) {
                return UIImage(data: data)
            }
        }
        
        // 2. Direct base64 string
        if urlString.count > 100 && !urlString.starts(with: "http") && !urlString.starts(with: "file:") {
            if let data = Data(base64Encoded: urlString, options: .ignoreUnknownCharacters) {
                return UIImage(data: data)
            }
        }
        
        // 3. Local file URL (file://...)
        if urlString.starts(with: "file://") {
            if let url = URL(string: urlString), let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }
        
        // 4. File in Documents directory by filename
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = docs.appendingPathComponent(urlString)
        if FileManager.default.fileExists(atPath: localURL.path), let data = try? Data(contentsOf: localURL) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    private var effectiveHttpImageURL: URL? {
        if let urlString = item.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           urlString.starts(with: "http://") || urlString.starts(with: "https://"),
           let url = URL(string: urlString) {
            return url
        }
        return defaultPhotoURL(for: item)
    }
    
    private var photoOverlayGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.35),
                Color.clear,
                Color.black.opacity(0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func defaultPhotoURL(for item: BorrowItem) -> URL? {
        let titleLower = item.title.lowercased()
        if titleLower.contains("drill") {
            return URL(string: "https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("tent") {
            return URL(string: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("chair") {
            return URL(string: "https://images.unsplash.com/photo-1510312305653-8ed496efae75?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("saw") {
            return URL(string: "https://images.unsplash.com/photo-1530124566582-a618bc2615dc?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("mixer") {
            return URL(string: "https://images.unsplash.com/photo-1594385208974-2e75f8d7bb48?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("kayak") {
            return URL(string: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("shears") || titleLower.contains("pruner") {
            return URL(string: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("ladder") {
            return URL(string: "https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("washer") {
            return URL(string: "https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?auto=format&fit=crop&w=800&q=80")
        } else if titleLower.contains("cleaner") {
            return URL(string: "https://images.unsplash.com/photo-1558317374-067fb5f30001?auto=format&fit=crop&w=800&q=80")
        }
        
        switch item.category {
        case .powerTools:
            return URL(string: "https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=800&q=80")
        case .handTools:
            return URL(string: "https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?auto=format&fit=crop&w=800&q=80")
        case .camping:
            return URL(string: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=800&q=80")
        case .kitchen:
            return URL(string: "https://images.unsplash.com/photo-1594385208974-2e75f8d7bb48?auto=format&fit=crop&w=800&q=80")
        case .garden:
            return URL(string: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=800&q=80")
        case .sports:
            return URL(string: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80")
        }
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let uiImage = localOrBase64Image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: height)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay(photoOverlayGradient)
                } else if let url = effectiveHttpImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: height)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .overlay(photoOverlayGradient)
                        case .failure:
                            fallbackVisual
                        case .empty:
                            ZStack {
                                Color(hex: item.category.colorHex).opacity(0.12)
                                ProgressView()
                                    .tint(Color(hex: item.category.colorHex))
                            }
                            .frame(height: height)
                        @unknown default:
                            fallbackVisual
                        }
                    }
                } else {
                    fallbackVisual
                }
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            
            // Community Free Lend Badge on Photo
            if item.isFree && height > 80 {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 10))
                    Text("FREE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.brandEmerald)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.25), radius: 4, y: 2)
                .padding(10)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private var fallbackVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(hex: item.category.colorHex).opacity(0.14))
                .frame(height: height)
            
            Image(systemName: item.systemImageName)
                .font(.system(size: height * 0.35, weight: .light))
                .foregroundColor(Color(hex: item.category.colorHex))
        }
    }
}

