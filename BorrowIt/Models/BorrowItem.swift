import Foundation
import CoreLocation

// MARK: - Item Category
public enum ItemCategory: String, CaseIterable, Identifiable, Codable {
    case powerTools = "Power Tools"
    case handTools = "Hand Tools"
    case camping = "Camping"
    case garden = "Garden"
    case kitchen = "Kitchen"
    case sports = "Sports"
    
    public var id: String { rawValue }
    
    public var sfSymbol: String {
        switch self {
        case .powerTools: return "bolt.fill"
        case .handTools: return "wrench.and.screwdriver.fill"
        case .camping: return "tent.fill"
        case .garden: return "leaf.fill"
        case .kitchen: return "fork.knife"
        case .sports: return "figure.run"
        }
    }
    
    public var colorHex: String {
        switch self {
        case .powerTools: return "#F59E0B" // Amber
        case .handTools: return "#6366F1"  // Indigo
        case .camping: return "#10B981"    // Emerald
        case .garden: return "#22C55E"     // Green
        case .kitchen: return "#EC4899"    // Pink
        case .sports: return "#3B82F6"     // Blue
        }
    }
}

// MARK: - Geo Coordinate
public struct Coordinate: Codable, Hashable {
    public var latitude: Double
    public var longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Lending Terms
public struct LendingTerms: Codable, Hashable {
    public var minDays: Int
    public var maxDays: Int
    public var depositHold: Double
    public var pricePerDay: Double
    
    public init(minDays: Int = 1, maxDays: Int = 7, depositHold: Double = 40.0, pricePerDay: Double = 8.0) {
        self.minDays = minDays
        self.maxDays = maxDays
        self.depositHold = depositHold
        self.pricePerDay = pricePerDay
    }
}

// MARK: - Lender Profile
public struct LenderProfile: Codable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var initials: String
    public var rating: Double
    public var reviewCount: Int
    public var joinedYear: Int
    public var totalLends: Int
    public var avatarColorHex: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        initials: String,
        rating: Double = 4.9,
        reviewCount: Int = 38,
        joinedYear: Int = 2024,
        totalLends: Int = 38,
        avatarColorHex: String = "#10B981"
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.rating = rating
        self.reviewCount = reviewCount
        self.joinedYear = joinedYear
        self.totalLends = totalLends
        self.avatarColorHex = avatarColorHex
    }
    
    public static let maya = LenderProfile(
        name: "Maya R.",
        initials: "MR",
        rating: 4.9,
        reviewCount: 42,
        joinedYear: 2024,
        totalLends: 38,
        avatarColorHex: "#10B981"
    )
    
    public static let jon = LenderProfile(
        name: "Jon L.",
        initials: "JL",
        rating: 4.8,
        reviewCount: 19,
        joinedYear: 2024,
        totalLends: 15,
        avatarColorHex: "#3B82F6"
    )
    
    public static let ari = LenderProfile(
        name: "Ari P.",
        initials: "AP",
        rating: 5.0,
        reviewCount: 27,
        joinedYear: 2023,
        totalLends: 31,
        avatarColorHex: "#8B5CF6"
    )
    
    public static let sam = LenderProfile(
        name: "Sam K.",
        initials: "SK",
        rating: 4.9,
        reviewCount: 14,
        joinedYear: 2025,
        totalLends: 12,
        avatarColorHex: "#EC4899"
    )
}

// MARK: - BorrowItem Model
public struct BorrowItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var description: String
    public var category: ItemCategory
    public var dailyRate: Double
    public var depositHold: Double
    public var distanceMeters: Double
    public var rating: Double
    public var isAvailable: Bool
    public var isAvailableWeekend: Bool
    public var pickupAddressSharedAfterApproval: Bool
    public var approximateAddress: String
    public var exactAddress: String
    public var coordinate: Coordinate
    public var lender: LenderProfile
    public var systemImageName: String
    public var imageURL: String?
    public var coreMLConfidence: Double
    public var coreMLTag: String
    public var terms: LendingTerms
    public var isFavorite: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: ItemCategory,
        dailyRate: Double,
        depositHold: Double,
        distanceMeters: Double,
        rating: Double = 4.9,
        isAvailable: Bool = true,
        isAvailableWeekend: Bool = true,
        pickupAddressSharedAfterApproval: Bool = true,
        approximateAddress: String = "Cedar Grove, within 500m",
        exactAddress: String = "42 Elmwood Ave, Cedar Grove",
        coordinate: Coordinate,
        lender: LenderProfile,
        systemImageName: String,
        imageURL: String? = nil,
        coreMLConfidence: Double = 0.94,
        coreMLTag: String? = nil,
        terms: LendingTerms? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.dailyRate = dailyRate
        self.depositHold = dailyRate <= 0 ? 0.0 : depositHold
        self.distanceMeters = distanceMeters
        self.rating = rating
        self.isAvailable = isAvailable
        self.isAvailableWeekend = isAvailableWeekend
        self.pickupAddressSharedAfterApproval = pickupAddressSharedAfterApproval
        self.approximateAddress = approximateAddress
        self.exactAddress = exactAddress
        self.coordinate = coordinate
        self.lender = lender
        self.systemImageName = systemImageName
        self.imageURL = imageURL
        self.coreMLConfidence = coreMLConfidence
        self.coreMLTag = coreMLTag ?? category.rawValue
        self.terms = terms ?? LendingTerms(depositHold: depositHold, pricePerDay: dailyRate)
        self.isFavorite = isFavorite
    }
    
    // MARK: - Resilient Codable Implementation for Cloud Database
    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, dailyRate, depositHold, distanceMeters, rating
        case isAvailable, isAvailableWeekend, pickupAddressSharedAfterApproval, approximateAddress
        case exactAddress, coordinate, lender, systemImageName, imageURL, coreMLConfidence
        case coreMLTag, terms, isFavorite
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(ItemCategory.self, forKey: .category)
        dailyRate = try container.decode(Double.self, forKey: .dailyRate)
        depositHold = try container.decode(Double.self, forKey: .depositHold)
        distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        rating = try container.decode(Double.self, forKey: .rating)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        isAvailableWeekend = try container.decode(Bool.self, forKey: .isAvailableWeekend)
        pickupAddressSharedAfterApproval = try container.decodeIfPresent(Bool.self, forKey: .pickupAddressSharedAfterApproval) ?? true
        approximateAddress = try container.decodeIfPresent(String.self, forKey: .approximateAddress) ?? ""
        exactAddress = try container.decodeIfPresent(String.self, forKey: .exactAddress) ?? ""
        coordinate = try container.decode(Coordinate.self, forKey: .coordinate)
        lender = try container.decode(LenderProfile.self, forKey: .lender)
        systemImageName = try container.decodeIfPresent(String.self, forKey: .systemImageName) ?? "bolt.fill"
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        coreMLConfidence = try container.decodeIfPresent(Double.self, forKey: .coreMLConfidence) ?? 0.94
        coreMLTag = try container.decodeIfPresent(String.self, forKey: .coreMLTag) ?? category.rawValue
        let decodedTerms = try container.decodeIfPresent(LendingTerms.self, forKey: .terms)
        terms = decodedTerms ?? LendingTerms(depositHold: depositHold, pricePerDay: dailyRate)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(dailyRate, forKey: .dailyRate)
        try container.encode(depositHold, forKey: .depositHold)
        try container.encode(distanceMeters, forKey: .distanceMeters)
        try container.encode(rating, forKey: .rating)
        try container.encode(isAvailable, forKey: .isAvailable)
        try container.encode(isAvailableWeekend, forKey: .isAvailableWeekend)
        try container.encode(pickupAddressSharedAfterApproval, forKey: .pickupAddressSharedAfterApproval)
        try container.encode(approximateAddress, forKey: .approximateAddress)
        try container.encode(exactAddress, forKey: .exactAddress)
        try container.encode(coordinate, forKey: .coordinate)
        try container.encode(lender, forKey: .lender)
        try container.encode(systemImageName, forKey: .systemImageName)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(coreMLConfidence, forKey: .coreMLConfidence)
        try container.encode(coreMLTag, forKey: .coreMLTag)
        try container.encode(terms, forKey: .terms)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
    
    public var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters))m away"
        } else {
            return String(format: "%.1f km away", distanceMeters / 1000.0)
        }
    }
    
    public var isFree: Bool {
        dailyRate <= 0
    }
    
    public var formattedRate: String {
        if isFree {
            return "Free"
        } else {
            return "Rs. \(Int(dailyRate))/day"
        }
    }
    
    public var formattedDeposit: String {
        if isFree || depositHold <= 0 {
            return "No deposit"
        } else {
            return "Rs. \(Int(depositHold)) hold"
        }
    }
    
    public var locationName: String {
        if !exactAddress.isEmpty {
            return exactAddress
        } else if !approximateAddress.isEmpty {
            return approximateAddress
        } else {
            return "Cedar Grove"
        }
    }
}

// MARK: - Rich Seed Dataset (Cedar Grove Neighborhood)
public extension BorrowItem {
    // Reference base center: 37.7749, -122.4194 (Cedar Grove Neighborhood)
    static let dewaltDrill = BorrowItem(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        title: "DeWalt 20V Cordless Drill",
        description: "Compact brushless hammer drill with two 20V MAX 2.0Ah batteries, rapid charger, and 30-piece drill/driver bit set. Perfect for hanging shelves, assemble furniture, and light masonry. Clean and fully charged.",
        category: .powerTools,
        dailyRate: 1500.0,
        depositHold: 5000.0,
        distanceMeters: 120.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 120m away",
        exactAddress: "148 Cedar Grove Lane",
        coordinate: Coordinate(latitude: 37.7758, longitude: -122.4188),
        lender: .maya,
        systemImageName: "bolt.fill",
        imageURL: "https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.96,
        coreMLTag: "Power Tools"
    )
    
    static let trailTent = BorrowItem(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        title: "2-Person Lightweight Trail Tent",
        description: "Waterproof 3-season backpacking tent with aluminum poles, vestibule, ground tarp, and carrying sack. Packs down under 4 lbs. Great for weekend trail trips or coastal camping.",
        category: .camping,
        dailyRate: 2500.0,
        depositHold: 8000.0,
        distanceMeters: 310.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 310m away",
        exactAddress: "224 Pinecrest Way",
        coordinate: Coordinate(latitude: 37.7765, longitude: -122.4215),
        lender: .jon,
        systemImageName: "tent.fill",
        imageURL: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.92,
        coreMLTag: "Camping"
    )
    
    static let campChairs = BorrowItem(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        title: "Folding Camp Chairs (Pair)",
        description: "Two durable, high-back folding camping chairs with cup holders, insulated armrests, and shoulder carry bags. Ideal for backyard movie nights, park picnics, or beach sunsets.",
        category: .camping,
        dailyRate: 1000.0,
        depositHold: 3000.0,
        distanceMeters: 320.0,
        rating: 4.7,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 320m away",
        exactAddress: "228 Pinecrest Way",
        coordinate: Coordinate(latitude: 37.7766, longitude: -122.4218),
        lender: .jon,
        systemImageName: "chair.lounge.fill",
        imageURL: "https://images.unsplash.com/photo-1510312305653-8ed496efae75?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.89,
        coreMLTag: "Camping"
    )
    
    static let circularSaw = BorrowItem(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        title: "Bosch 7-1/4\" Circular Saw",
        description: "Heavy-duty 15-amp circular saw with laser guide line, carbide-tipped 24T wood blade, and dust chute. Ready for 2x4 framing, plywood cuts, and deck repair.",
        category: .powerTools,
        dailyRate: 2800.0,
        depositHold: 9000.0,
        distanceMeters: 440.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: false,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 440m away",
        exactAddress: "310 Willow Court",
        coordinate: Coordinate(latitude: 37.7732, longitude: -122.4162),
        lender: .ari,
        systemImageName: "gearshape.2.fill",
        imageURL: "https://images.unsplash.com/photo-1581147036324-c17ac41dfa6c?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.95,
        coreMLTag: "Power Tools"
    )
    
    static let standMixer = BorrowItem(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        title: "KitchenAid 5-Qt Artisan Stand Mixer",
        description: "Classic tilt-head stand mixer in Empire Red. Includes stainless steel bowl, flat beater, dough hook, wire whisk, and pouring shield. Perfect for weekend bread baking or holiday cookies.",
        category: .kitchen,
        dailyRate: 2000.0,
        depositHold: 12000.0,
        distanceMeters: 150.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 150m away",
        exactAddress: "152 Cedar Grove Lane",
        coordinate: Coordinate(latitude: 37.7755, longitude: -122.4182),
        lender: .maya,
        systemImageName: "fork.knife",
        imageURL: "https://images.unsplash.com/photo-1594385208974-2e75f8d7bb48?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.97,
        coreMLTag: "Kitchen"
    )
    
    static let kayakSet = BorrowItem(
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        title: "Inflatable Kayak & Paddle Set",
        description: "Heavy-duty 1-person tandem-capable inflatable kayak with dual paddles, high-output hand pump, and adult life vest. Fits neatly in trunk.",
        category: .sports,
        dailyRate: 3500.0,
        depositHold: 15000.0,
        distanceMeters: 480.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 480m away",
        exactAddress: "89 Orchard Pass",
        coordinate: Coordinate(latitude: 37.7782, longitude: -122.4222),
        lender: .sam,
        systemImageName: "figure.open.water.swim",
        imageURL: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.91,
        coreMLTag: "Sports"
    )
    
    static let gardenShears = BorrowItem(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        title: "Fiskars Telescoping Tree Pruner & Shears",
        description: "Extendable tree pruner up to 14 ft with sharp hardened bypass blade and 12-inch wood saw. Cut high branches easily without a ladder.",
        category: .garden,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0, // Free items require no deposit hold
        distanceMeters: 210.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 210m away",
        exactAddress: "72 Maple Avenue",
        coordinate: Coordinate(latitude: 37.7741, longitude: -122.4208),
        lender: .ari,
        systemImageName: "leaf.fill",
        imageURL: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.93,
        coreMLTag: "Garden"
    )
    
    static let telescopingLadder = BorrowItem(
        id: UUID(uuidString: "99999999-1111-2222-3333-444444444444")!,
        title: "Little Giant 17ft Multi-Position Ladder",
        description: "Heavy-duty aluminum telescoping ladder. Converts from A-frame step ladder (4-7ft) to 17ft extension ladder. Essential for seasonal gutter cleaning, cathedral ceiling bulbs, and exterior painting. Folds down to 4.5ft to fit in any car trunk.",
        category: .handTools,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0, // Free items require no deposit hold
        distanceMeters: 90.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 90m away",
        exactAddress: "142 Cedar Grove Lane",
        coordinate: Coordinate(latitude: 37.7753, longitude: -122.4190),
        lender: .maya,
        systemImageName: "arrow.up.and.down",
        imageURL: "https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.98,
        coreMLTag: "Hand Tools"
    )
    
    static let pressureWasher = BorrowItem(
        id: UUID(uuidString: "99999999-2222-3333-4444-555555555555")!,
        title: "Kärcher 1800-PSI High-Pressure Washer",
        description: "Electric power washer with 25ft high-pressure hose, turbo nozzle, and detergent tank. Ideal for seasonal driveway cleaning, moss removal on patios, deck rejuvenation, and detailing cars.",
        category: .powerTools,
        dailyRate: 1800.0,
        depositHold: 6000.0,
        distanceMeters: 260.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 260m away",
        exactAddress: "185 Pinecrest Way",
        coordinate: Coordinate(latitude: 37.7761, longitude: -122.4210),
        lender: .ari,
        systemImageName: "drop.fill",
        imageURL: "https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.96,
        coreMLTag: "Power Tools"
    )
    
    static let carpetCleaner = BorrowItem(
        id: UUID(uuidString: "99999999-3333-4444-5555-666666666666")!,
        title: "Bissell ProHeat Carpet & Upholstery Cleaner",
        description: "Deep-cleaning upright carpet shampooer with specialized pet-stain hand tool and 8ft hose. Perfect for deep annual carpet refreshes, sofa stains, and car interior detailing.",
        category: .powerTools,
        dailyRate: 2000.0,
        depositHold: 5000.0,
        distanceMeters: 170.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 170m away",
        exactAddress: "155 Cedar Grove Lane",
        coordinate: Coordinate(latitude: 37.7756, longitude: -122.4184),
        lender: .sam,
        systemImageName: "sparkles",
        imageURL: "https://images.unsplash.com/photo-1558317374-067fb5f30001?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Power Tools"
    )
    
    static let studFinderLevel = BorrowItem(
        id: UUID(uuidString: "99999999-4444-5555-6666-777777777777")!,
        title: "Bosch Digital Wall Scanner & Laser Level",
        description: "Precision digital multi-scanner detects wood studs, metal pipes, and live electrical wiring behind drywall up to 4.75 inches. Includes self-leveling cross-line laser. Avoid drilling into pipes when mounting TVs, mirrors, or heavy shelving.",
        category: .handTools,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 1500.0,
        distanceMeters: 110.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 110m away",
        exactAddress: "145 Cedar Grove Lane",
        coordinate: Coordinate(latitude: 37.7754, longitude: -122.4189),
        lender: .jon,
        systemImageName: "ruler.fill",
        imageURL: "https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.96,
        coreMLTag: "Hand Tools"
    )
    
    static let eventTableChairs = BorrowItem(
        id: UUID(uuidString: "99999999-5555-6666-7777-888888888888")!,
        title: "Lifetime 6ft Folding Banquet Table & Chairs",
        description: "Heavy-duty 6-foot fold-in-half utility table with 4 contoured folding chairs. Stain-resistant, weather-proof, and lightweight with carry handle. Ideal for birthday parties, family holiday dinners, garage sales, and community cookouts.",
        category: .camping,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 2500.0,
        distanceMeters: 310.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 310m away",
        exactAddress: "225 Pinecrest Way",
        coordinate: Coordinate(latitude: 37.7764, longitude: -122.4214),
        lender: .maya,
        systemImageName: "table.furniture.fill",
        imageURL: "https://images.unsplash.com/photo-1510312305653-8ed496efae75?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Camping"
    )
    
    static let socketSet = BorrowItem(
        id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
        title: "Stanley 65-Piece Home Tool Set",
        description: "Complete mechanics and homeowner ratchet set: standard & metric sockets, hex keys, precision screwdrivers, tape measure, and hammer in a blow-mold case.",
        category: .handTools,
        dailyRate: 1000.0,
        depositHold: 3500.0,
        distanceMeters: 330.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Cedar Grove · 330m away",
        exactAddress: "230 Pinecrest Way",
        coordinate: Coordinate(latitude: 37.7768, longitude: -122.4219),
        lender: .jon,
        systemImageName: "wrench.and.screwdriver.fill",
        imageURL: "https://images.unsplash.com/photo-1581244277943-fe4a9c777189?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Hand Tools"
    )
    
    static let allSeedItems: [BorrowItem] = [
        telescopingLadder,
        dewaltDrill,
        pressureWasher,
        carpetCleaner,
        studFinderLevel,
        eventTableChairs,
        trailTent,
        campChairs,
        circularSaw,
        standMixer,
        kayakSet,
        gardenShears,
        socketSet
    ]
}
