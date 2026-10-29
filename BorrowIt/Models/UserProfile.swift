import Foundation

// MARK: - Monthly Saving Data Point for Swift Charts
public struct MonthlySaving: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var month: String
    public var amountSaved: Double
    public var isCurrentMonth: Bool
    
    public init(id: UUID = UUID(), month: String, amountSaved: Double, isCurrentMonth: Bool = false) {
        self.id = id
        self.month = month
        self.amountSaved = amountSaved
        self.isCurrentMonth = isCurrentMonth
    }
}

// MARK: - User Profile Model
public struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var email: String
    public var initials: String
    public var neighborhood: String
    public var memberSince: String
    public var isIdVerified: Bool
    public var trustScore: Int
    public var trustScoreSubtitle: String
    public var communityRating: Double
    public var reviewCount: Int
    public var totalBorrows: Int
    public var totalLends: Int
    public var wasteAvoidedKg: Double
    public var totalMoneySaved: Double
    public var monthlySavings: [MonthlySaving]
    public var avatarImageData: Data?
    public var avatarImageURL: String?
    
    public init(
        id: UUID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        name: String = "Alex Morgan",
        email: String = "alex@icloud.com",
        initials: String = "AM",
        neighborhood: String = "Cedar Grove",
        memberSince: String = "Neighbor since 2025",
        isIdVerified: Bool = true,
        trustScore: Int = 94,
        trustScoreSubtitle: String = "Top 10% nearby",
        communityRating: Double = 4.9,
        reviewCount: Int = 23,
        totalBorrows: Int = 18,
        totalLends: Int = 11,
        wasteAvoidedKg: Double = 42.0,
        totalMoneySaved: Double = 45000.0,
        monthlySavings: [MonthlySaving] = Self.defaultMonthlySavings,
        avatarImageData: Data? = nil,
        avatarImageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.initials = initials
        self.neighborhood = neighborhood
        self.memberSince = memberSince
        self.isIdVerified = isIdVerified
        self.trustScore = trustScore
        self.trustScoreSubtitle = trustScoreSubtitle
        self.communityRating = communityRating
        self.reviewCount = reviewCount
        self.totalBorrows = totalBorrows
        self.totalLends = totalLends
        self.wasteAvoidedKg = wasteAvoidedKg
        self.totalMoneySaved = totalMoneySaved
        self.monthlySavings = monthlySavings
        self.avatarImageData = avatarImageData
        self.avatarImageURL = avatarImageURL
    }
    
    public static let defaultMonthlySavings: [MonthlySaving] = [
        MonthlySaving(month: "May", amountSaved: 5000.0, isCurrentMonth: false),
        MonthlySaving(month: "Jun", amountSaved: 7500.0, isCurrentMonth: false),
        MonthlySaving(month: "Jul", amountSaved: 9500.0, isCurrentMonth: false),
        MonthlySaving(month: "Aug", amountSaved: 8000.0, isCurrentMonth: false),
        MonthlySaving(month: "Sep", amountSaved: 11000.0, isCurrentMonth: false),
        MonthlySaving(month: "Oct", amountSaved: 6000.0, isCurrentMonth: true)
    ]
    
    public static let currentUser = UserProfile()
    
    // MARK: - Resilient Database Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case id, name, email, initials, neighborhood, memberSince, isIdVerified
        case trustScore, trustScoreSubtitle, communityRating, reviewCount
        case totalBorrows, totalLends, wasteAvoidedKg, totalMoneySaved
        case monthlySavings, avatarImageURL
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        initials = try container.decodeIfPresent(String.self, forKey: .initials) ?? "U"
        neighborhood = try container.decodeIfPresent(String.self, forKey: .neighborhood) ?? "Cedar Grove"
        memberSince = try container.decodeIfPresent(String.self, forKey: .memberSince) ?? "Neighbor since 2026"
        isIdVerified = try container.decodeIfPresent(Bool.self, forKey: .isIdVerified) ?? true
        trustScore = try container.decodeIfPresent(Int.self, forKey: .trustScore) ?? 95
        trustScoreSubtitle = try container.decodeIfPresent(String.self, forKey: .trustScoreSubtitle) ?? "Verified Member"
        communityRating = try container.decodeIfPresent(Double.self, forKey: .communityRating) ?? 5.0
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
        totalBorrows = try container.decodeIfPresent(Int.self, forKey: .totalBorrows) ?? 0
        totalLends = try container.decodeIfPresent(Int.self, forKey: .totalLends) ?? 0
        wasteAvoidedKg = try container.decodeIfPresent(Double.self, forKey: .wasteAvoidedKg) ?? 0.0
        totalMoneySaved = try container.decodeIfPresent(Double.self, forKey: .totalMoneySaved) ?? 0.0
        monthlySavings = try container.decodeIfPresent([MonthlySaving].self, forKey: .monthlySavings) ?? Self.defaultMonthlySavings
        avatarImageURL = try container.decodeIfPresent(String.self, forKey: .avatarImageURL)
        avatarImageData = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(initials, forKey: .initials)
        try container.encode(neighborhood, forKey: .neighborhood)
        try container.encode(memberSince, forKey: .memberSince)
        try container.encode(isIdVerified, forKey: .isIdVerified)
        try container.encode(trustScore, forKey: .trustScore)
        try container.encode(trustScoreSubtitle, forKey: .trustScoreSubtitle)
        try container.encode(communityRating, forKey: .communityRating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(totalBorrows, forKey: .totalBorrows)
        try container.encode(totalLends, forKey: .totalLends)
        try container.encode(wasteAvoidedKg, forKey: .wasteAvoidedKg)
        try container.encode(totalMoneySaved, forKey: .totalMoneySaved)
        try container.encode(monthlySavings, forKey: .monthlySavings)
        try container.encodeIfPresent(avatarImageURL, forKey: .avatarImageURL)
    }
}
