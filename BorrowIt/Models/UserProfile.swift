import Foundation

// MARK: - Monthly Saving Data Point for Swift Charts
public struct MonthlySaving: Identifiable, Codable, Hashable {
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
public struct UserProfile: Identifiable, Codable, Hashable {
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
        totalMoneySaved: Double = 312.0,
        monthlySavings: [MonthlySaving] = Self.defaultMonthlySavings
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
    }
    
    public static let defaultMonthlySavings: [MonthlySaving] = [
        MonthlySaving(month: "May", amountSaved: 35.0, isCurrentMonth: false),
        MonthlySaving(month: "Jun", amountSaved: 48.0, isCurrentMonth: false),
        MonthlySaving(month: "Jul", amountSaved: 62.0, isCurrentMonth: false),
        MonthlySaving(month: "Aug", amountSaved: 55.0, isCurrentMonth: false),
        MonthlySaving(month: "Sep", amountSaved: 72.0, isCurrentMonth: false),
        MonthlySaving(month: "Oct", amountSaved: 40.0, isCurrentMonth: true)
    ]
    
    public static let currentUser = UserProfile()
}
