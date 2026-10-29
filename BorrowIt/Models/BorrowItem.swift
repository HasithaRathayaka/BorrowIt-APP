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
        id: UUID(uuidString: "aaaaaaaa-1111-2222-3333-444444444444")!,
        name: "Maya R.",
        initials: "MR",
        rating: 4.9,
        reviewCount: 42,
        joinedYear: 2024,
        totalLends: 38,
        avatarColorHex: "#10B981"
    )
    
    public static let kasun = LenderProfile(
        id: UUID(uuidString: "bbbbbbbb-1111-2222-3333-444444444444")!,
        name: "Kasun P.",
        initials: "KP",
        rating: 4.9,
        reviewCount: 34,
        joinedYear: 2024,
        totalLends: 29,
        avatarColorHex: "#3B82F6"
    )
    
    public static let dilshan = LenderProfile(
        id: UUID(uuidString: "cccccccc-1111-2222-3333-444444444444")!,
        name: "Dilshan S.",
        initials: "DS",
        rating: 4.8,
        reviewCount: 22,
        joinedYear: 2024,
        totalLends: 18,
        avatarColorHex: "#F59E0B"
    )
    
    public static let chamari = LenderProfile(
        id: UUID(uuidString: "dddddddd-1111-2222-3333-444444444444")!,
        name: "Chamari F.",
        initials: "CF",
        rating: 5.0,
        reviewCount: 31,
        joinedYear: 2023,
        totalLends: 35,
        avatarColorHex: "#EC4899"
    )
    
    public static let nuwan = LenderProfile(
        id: UUID(uuidString: "eeeeeeee-1111-2222-3333-444444444444")!,
        name: "Nuwan J.",
        initials: "NJ",
        rating: 4.9,
        reviewCount: 19,
        joinedYear: 2025,
        totalLends: 16,
        avatarColorHex: "#8B5CF6"
    )
    
    public static let anusha = LenderProfile(
        id: UUID(uuidString: "ffffffff-1111-2222-3333-444444444444")!,
        name: "Anusha W.",
        initials: "AW",
        rating: 4.8,
        reviewCount: 15,
        joinedYear: 2025,
        totalLends: 12,
        avatarColorHex: "#14B8A6"
    )
    
    // Backwards-compatibility aliases
    public static let jon = dilshan
    public static let ari = nuwan
    public static let sam = chamari
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
        approximateAddress: String = "Colombo 07, within 500m",
        exactAddress: String = "42 Reid Avenue, Colombo 07",
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
            return "Colombo 07"
        }
    }
}

// MARK: - Rich Seed Dataset (Colombo 07 Neighborhood)
public extension BorrowItem {
    // Reference base center: 6.9064, 79.8708 (Colombo 07 - Cinnamon Gardens / Reid Ave)
    
    // MARK: Power Tools
    static let dewaltDrill = BorrowItem(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        title: "DeWalt 20V Cordless Drill & Masonry Bits",
        description: "Compact brushless hammer drill with two 20V MAX 2.0Ah batteries, rapid charger, and 30-piece drill/driver bit set. Perfect for hanging wall art, assembling furniture, and light brick masonry.",
        category: .powerTools,
        dailyRate: 1500.0,
        depositHold: 5000.0,
        distanceMeters: 120.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 120m away",
        exactAddress: "148 Reid Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9072, longitude: 79.8715),
        lender: .maya,
        systemImageName: "bolt.fill",
        imageURL: "https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.96,
        coreMLTag: "Power Tools"
    )
    
    static let angleGrinder = BorrowItem(
        id: UUID(uuidString: "aaaa1111-0001-0001-0001-000000000001")!,
        title: "Makita 4-Inch Angle Grinder & Cutting Discs",
        description: "840W handheld angle grinder with protective wheel guard, side handle, and assortment of metal cutting and tile grinding discs. Free for neighborhood DIY and metal repairs.",
        category: .powerTools,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 140.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 140m away",
        exactAddress: "18 Cambridge Place, Colombo 07",
        coordinate: Coordinate(latitude: 6.9082, longitude: 79.8692),
        lender: .dilshan,
        systemImageName: "circle.dashed",
        imageURL: "https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Power Tools"
    )
    
    static let rotaryHammerDrill = BorrowItem(
        id: UUID(uuidString: "aaaa1111-0001-0001-0001-000000000002")!,
        title: "Bosch SDS Rotary Hammer Drill (Concrete Bore)",
        description: "Heavy-duty 800W rotary hammer with 3 modes (drilling, hammer drilling, chiseling) and SDS-Plus bits. Essential for penetrating thick reinforced concrete slabs and granite walls.",
        category: .powerTools,
        dailyRate: 1800.0,
        depositHold: 6000.0,
        distanceMeters: 230.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 230m away",
        exactAddress: "56 Thurstan Road, Colombo 07",
        coordinate: Coordinate(latitude: 6.9056, longitude: 79.8690),
        lender: .kasun,
        systemImageName: "hammer.fill",
        imageURL: "https://images.unsplash.com/photo-1581147036324-c17ac41dfa6c?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.95,
        coreMLTag: "Power Tools"
    )
    
    static let pressureWasher = BorrowItem(
        id: UUID(uuidString: "99999999-2222-3333-4444-555555555555")!,
        title: "Kärcher 1800-PSI High-Pressure Washer",
        description: "Electric power washer with 25ft high-pressure hose, dirt-blaster rotary turbo lance, and detergent tank. Ideal for monsoon patio washdown, moss removal on brick driveways, and car detailing.",
        category: .powerTools,
        dailyRate: 2000.0,
        depositHold: 6000.0,
        distanceMeters: 260.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 260m away",
        exactAddress: "44 Thurstan Road, Colombo 07",
        coordinate: Coordinate(latitude: 6.9052, longitude: 79.8688),
        lender: .nuwan,
        systemImageName: "drop.fill",
        imageURL: "https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.96,
        coreMLTag: "Power Tools"
    )
    
    static let circularSaw = BorrowItem(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        title: "Bosch 7-1/4\" Circular Saw & Guide Rail",
        description: "Heavy-duty 15-amp circular saw with laser cut guide, carbide-tipped 24T wood blade, and dust chute. Ready for carpentry, timber framing, and plywood cutting.",
        category: .powerTools,
        dailyRate: 2500.0,
        depositHold: 8000.0,
        distanceMeters: 440.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: false,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 440m away",
        exactAddress: "310 Torrington Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9032, longitude: 79.8732),
        lender: .nuwan,
        systemImageName: "gearshape.2.fill",
        imageURL: "https://images.unsplash.com/photo-1581147036324-c17ac41dfa6c?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.95,
        coreMLTag: "Power Tools"
    )
    
    // MARK: Hand Tools
    static let telescopingLadder = BorrowItem(
        id: UUID(uuidString: "99999999-1111-2222-3333-444444444444")!,
        title: "Little Giant 17ft Multi-Position Ladder",
        description: "Heavy-duty aluminum telescoping ladder. Converts from A-frame step ladder (4-7ft) to 17ft extension ladder. Essential for gutter cleaning, ceiling lights, and rooftop maintenance. Folds to 4.5ft.",
        category: .handTools,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 90.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 90m away",
        exactAddress: "142 Reid Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9070, longitude: 79.8713),
        lender: .maya,
        systemImageName: "arrow.up.and.down",
        imageURL: "https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.98,
        coreMLTag: "Hand Tools"
    )
    
    static let studFinderLevel = BorrowItem(
        id: UUID(uuidString: "99999999-4444-5555-6666-777777777777")!,
        title: "Bosch Digital Wall Scanner & Laser Level",
        description: "Precision digital multi-scanner detects electrical conduit, metal rebar, and wooden battens up to 4.75 inches behind plaster walls. Includes cross-line laser. Avoid drilling into water pipes when hanging mirrors or TVs.",
        category: .handTools,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 110.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 110m away",
        exactAddress: "65 Guilford Crescent, Colombo 07",
        coordinate: Coordinate(latitude: 6.9071, longitude: 79.8701),
        lender: .dilshan,
        systemImageName: "ruler.fill",
        imageURL: "https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.96,
        coreMLTag: "Hand Tools"
    )
    
    static let pipeWrenchSet = BorrowItem(
        id: UUID(uuidString: "aaaa2222-0002-0002-0002-000000000001")!,
        title: "Heavy Duty Plumbing Pipe Wrench & Teflon Kit",
        description: "Set of 10-inch and 14-inch drop-forged steel pipe wrenches with non-slip grooved jaws, pipe cutter, and Teflon sealing tape rolls. Perfect for kitchen sink repairs and water pump plumbing.",
        category: .handTools,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 190.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 190m away",
        exactAddress: "12 Racecourse Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9075, longitude: 79.8718),
        lender: .kasun,
        systemImageName: "wrench.adjustable.fill",
        imageURL: "https://images.unsplash.com/photo-1581244277943-fe4a9c777189?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.93,
        coreMLTag: "Hand Tools"
    )
    
    static let socketSet = BorrowItem(
        id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
        title: "Stanley 65-Piece Mechanics Socket & Ratchet Set",
        description: "Complete mechanics and homeowner ratchet set: standard & metric sockets, hex keys, precision screwdrivers, tape measure, and hammer in a heavy-duty blow-mold case.",
        category: .handTools,
        dailyRate: 1000.0,
        depositHold: 3500.0,
        distanceMeters: 330.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 330m away",
        exactAddress: "26 Cambridge Place, Colombo 07",
        coordinate: Coordinate(latitude: 6.9087, longitude: 79.8687),
        lender: .dilshan,
        systemImageName: "wrench.and.screwdriver.fill",
        imageURL: "https://images.unsplash.com/photo-1581244277943-fe4a9c777189?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Hand Tools"
    )
    
    // MARK: Garden & Outdoor
    static let gardenShears = BorrowItem(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        title: "Fiskars Telescoping Tree Pruner & Hedge Shears",
        description: "Extendable tree pruner up to 14 ft with sharp hardened bypass blade and 12-inch wood saw. Cut high mango branches and overgrown coconut fronds safely without a tall ladder.",
        category: .garden,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 210.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 210m away",
        exactAddress: "82 Bauddhaloka Mawatha, Colombo 07",
        coordinate: Coordinate(latitude: 6.9046, longitude: 79.8713),
        lender: .nuwan,
        systemImageName: "scissors",
        imageURL: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.93,
        coreMLTag: "Garden"
    )
    
    static let wheelbarrowUdalla = BorrowItem(
        id: UUID(uuidString: "aaaa3333-0003-0003-0003-000000000001")!,
        title: "Garden Wheelbarrow & Heavy Udalla (Mamoty)",
        description: "Heavy-duty steel wheelbarrow with pneumatic tire, paired with a forged steel Sri Lankan Udalla (hoe/mamoty) and rake. Great for garden landscaping, soil moving, and compound leveling.",
        category: .garden,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 160.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 160m away",
        exactAddress: "15 Independence Square, Colombo 07",
        coordinate: Coordinate(latitude: 6.9048, longitude: 79.8698),
        lender: .anusha,
        systemImageName: "cart.fill",
        imageURL: "https://images.unsplash.com/photo-1590682680695-43b964a3ae17?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.92,
        coreMLTag: "Garden"
    )
    
    static let brushCutter = BorrowItem(
        id: UUID(uuidString: "aaaa3333-0003-0003-0003-000000000002")!,
        title: "Honda 4-Stroke Petrol Grass Brush Cutter",
        description: "Commercial Honda GX35 4-stroke petrol trimmer with shoulder harness, nylon bump feed head, and 3-tooth steel brush blade. Clears dense tropical weeds and overgrown lawns quickly.",
        category: .garden,
        dailyRate: 2500.0,
        depositHold: 7000.0,
        distanceMeters: 380.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 380m away",
        exactAddress: "48 Gregory's Road, Colombo 07",
        coordinate: Coordinate(latitude: 6.9094, longitude: 79.8739),
        lender: .chamari,
        systemImageName: "leaf.fill",
        imageURL: "https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.95,
        coreMLTag: "Garden"
    )
    
    static let gardenHoseSprinkler = BorrowItem(
        id: UUID(uuidString: "aaaa3333-0003-0003-0003-000000000003")!,
        title: "30m Heavy Duty Garden Hose & Sprinkler",
        description: "30-meter reinforced anti-kink garden hose reel with multi-spray brass trigger nozzle and oscillating lawn sprinkler. Great for dry season lawn maintenance and garden hydration.",
        category: .garden,
        dailyRate: 600.0,
        depositHold: 2000.0,
        distanceMeters: 290.0,
        rating: 4.7,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 290m away",
        exactAddress: "162 Reid Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9079, longitude: 79.8724),
        lender: .maya,
        systemImageName: "humidity.fill",
        imageURL: "https://images.unsplash.com/photo-1584473457406-6240486418e9?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.90,
        coreMLTag: "Garden"
    )
    
    // MARK: Kitchenware
    static let coconutScraper = BorrowItem(
        id: UUID(uuidString: "aaaa4444-0004-0004-0004-000000000001")!,
        title: "Electric Coconut Scraper (Pol Gana Mese)",
        description: "Heavy-duty electric motorized coconut scraper table with stainless steel rotary blade, protective splatter guard, and safety toggle switch. Scrapes fresh coconuts cleanly in under 30 seconds.",
        category: .kitchen,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 80.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 80m away",
        exactAddress: "14 Racecourse Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9069, longitude: 79.8711),
        lender: .chamari,
        systemImageName: "circle.hexagongrid.fill",
        imageURL: "https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.97,
        coreMLTag: "Kitchen"
    )
    
    static let stringHopperPress = BorrowItem(
        id: UUID(uuidString: "aaaa4444-0004-0004-0004-000000000002")!,
        title: "Brass String Hopper Press & Bamboo Watti",
        description: "Authentic solid brass Idiyappam / String Hopper press with ergonomic leverage stand and 50 traditional bamboo steaming watti. Cleaned and sanitized for weekend family feasts or almsgiving.",
        category: .kitchen,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 130.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 130m away",
        exactAddress: "52 Guilford Crescent, Colombo 07",
        coordinate: Coordinate(latitude: 6.9073, longitude: 79.8703),
        lender: .anusha,
        systemImageName: "tray.2.fill",
        imageURL: "https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.95,
        coreMLTag: "Kitchen"
    )
    
    static let biryaniCauldron = BorrowItem(
        id: UUID(uuidString: "aaaa4444-0004-0004-0004-000000000003")!,
        title: "Cast Aluminum Jumbo Biryani Degchi Cauldron",
        description: "Commercial 50-serving thick cast aluminum degchi with heavy tight-fit lid. Ideal for slow charcoal dum biryani, ghee rice, wedding functions, and festive neighborhood gatherings.",
        category: .kitchen,
        dailyRate: 1200.0,
        depositHold: 4000.0,
        distanceMeters: 350.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 350m away",
        exactAddress: "8 Flower Road, Colombo 07",
        coordinate: Coordinate(latitude: 6.9089, longitude: 79.8672),
        lender: .kasun,
        systemImageName: "flame.fill",
        imageURL: "https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Kitchen"
    )
    
    static let mixerGrinder = BorrowItem(
        id: UUID(uuidString: "aaaa4444-0004-0004-0004-000000000004")!,
        title: "Preethi 750W Heavy Duty Mixer Grinder",
        description: "Powerful 750W Indian/Sri Lankan mixer grinder with 3 heavy stainless steel jars. Effortlessly crushes roasted curry spices, coconut sambol, chili pastes, and dosa batter.",
        category: .kitchen,
        dailyRate: 900.0,
        depositHold: 3000.0,
        distanceMeters: 270.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 270m away",
        exactAddress: "14 Cambridge Place, Colombo 07",
        coordinate: Coordinate(latitude: 6.9080, longitude: 79.8696),
        lender: .dilshan,
        systemImageName: "fork.knife",
        imageURL: "https://images.unsplash.com/photo-1570222094114-d054a817e56b?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.95,
        coreMLTag: "Kitchen"
    )
    
    static let standMixer = BorrowItem(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        title: "KitchenAid 5-Qt Artisan Stand Mixer",
        description: "Classic tilt-head stand mixer in Empire Red. Includes stainless steel bowl, flat beater, dough hook, wire whisk, and pouring shield. Perfect for artisan bread baking and birthday cakes.",
        category: .kitchen,
        dailyRate: 2000.0,
        depositHold: 12000.0,
        distanceMeters: 150.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 150m away",
        exactAddress: "28 Racecourse Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9077, longitude: 79.8712),
        lender: .maya,
        systemImageName: "fork.knife",
        imageURL: "https://images.unsplash.com/photo-1594385208974-2e75f8d7bb48?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.97,
        coreMLTag: "Kitchen"
    )
    
    // MARK: Camping & Outdoor Events
    static let campingStove = BorrowItem(
        id: UUID(uuidString: "aaaa5555-0005-0005-0005-000000000001")!,
        title: "Portable Butane Camping Stove & Windshield",
        description: "Compact single-burner outdoor butane cooker with piezo auto-ignition, hard carry case, and folding aluminum windscreen. Perfect for beach sunsets, Knuckles hikes, or outdoor cooking.",
        category: .camping,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 180.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 180m away",
        exactAddress: "7 Maitland Crescent, Colombo 07",
        coordinate: Coordinate(latitude: 6.9078, longitude: 79.8720),
        lender: .nuwan,
        systemImageName: "flame.circle.fill",
        imageURL: "https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.92,
        coreMLTag: "Camping"
    )
    
    static let trailTent = BorrowItem(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        title: "Coleman 4-Person Waterproof Dome Tent & Tarp",
        description: "Waterproof WeatherTec 4-person dome tent with fiberglass poles, vestibule, ground tarp, and compact carrying sack. Great for weekend trail trips to Ella, Horton Plains, or coastal camping.",
        category: .camping,
        dailyRate: 2200.0,
        depositHold: 8000.0,
        distanceMeters: 310.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 310m away",
        exactAddress: "19 Cambridge Place, Colombo 07",
        coordinate: Coordinate(latitude: 6.9085, longitude: 79.8689),
        lender: .dilshan,
        systemImageName: "tent.fill",
        imageURL: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.92,
        coreMLTag: "Camping"
    )
    
    static let campChairs = BorrowItem(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        title: "Folding Camp Chairs (Pair) with Cup Holders",
        description: "Two durable, high-back folding camping chairs with mesh cup holders, insulated armrests, and shoulder carry bags. Ideal for backyard movie nights, park picnics, or beach sunsets.",
        category: .camping,
        dailyRate: 800.0,
        depositHold: 2500.0,
        distanceMeters: 320.0,
        rating: 4.7,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 320m away",
        exactAddress: "22 Cambridge Place, Colombo 07",
        coordinate: Coordinate(latitude: 6.9086, longitude: 79.8688),
        lender: .dilshan,
        systemImageName: "chair.lounge.fill",
        imageURL: "https://images.unsplash.com/photo-1510312305653-8ed496efae75?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.89,
        coreMLTag: "Camping"
    )
    
    static let coolerBox = BorrowItem(
        id: UUID(uuidString: "aaaa5555-0005-0005-0005-000000000002")!,
        title: "Igloo 50-Liter Heavy Duty Ice Cooler Box",
        description: "Rugged 50L insulated cooler with heavy-duty all-terrain wheels, telescoping tow handle, drain plug, and 3-day ice retention. Fits up to 80 cans. Perfect for cricket match tailgates.",
        category: .camping,
        dailyRate: 1000.0,
        depositHold: 3500.0,
        distanceMeters: 240.0,
        rating: 4.8,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 240m away",
        exactAddress: "32 Gregory's Road, Colombo 07",
        coordinate: Coordinate(latitude: 6.9081, longitude: 79.8735),
        lender: .chamari,
        systemImageName: "cube.fill",
        imageURL: "https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.91,
        coreMLTag: "Camping"
    )
    
    static let eventTableChairs = BorrowItem(
        id: UUID(uuidString: "99999999-5555-6666-7777-888888888888")!,
        title: "Lifetime 6ft Folding Banquet Table & Chairs",
        description: "Heavy-duty 6-foot fold-in-half utility table with 4 contoured folding chairs. Stain-resistant, weather-proof, and lightweight with carry handle. Ideal for birthday parties and family gatherings.",
        category: .camping,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 310.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 310m away",
        exactAddress: "40 Independence Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9042, longitude: 79.8727),
        lender: .maya,
        systemImageName: "table.furniture.fill",
        imageURL: "https://images.unsplash.com/photo-1510312305653-8ed496efae75?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Camping"
    )
    
    // MARK: Sports & Leisure
    static let carromBoard = BorrowItem(
        id: UUID(uuidString: "aaaa6666-0006-0006-0006-000000000001")!,
        title: "Tournament Carrom Board & Striker Set",
        description: "Championship 35-inch English birchwood carrom board with fast waterproof surface, premium carrom men (coins), 15g tournament striker, and boric powder. Great for rainy day family matches.",
        category: .sports,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 100.0,
        rating: 5.0,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 100m away",
        exactAddress: "138 Reid Avenue, Colombo 07",
        coordinate: Coordinate(latitude: 6.9068, longitude: 79.8711),
        lender: .kasun,
        systemImageName: "square.grid.2x2.fill",
        imageURL: "https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.93,
        coreMLTag: "Sports"
    )
    
    static let badmintonSet = BorrowItem(
        id: UUID(uuidString: "aaaa6666-0006-0006-0006-000000000002")!,
        title: "Yonex 4-Racket Badminton Set & Net",
        description: "Complete recreational badminton kit: 4 graphite-shaft Yonex rackets, freestanding portable net stand, and tube of 6 durable nylon shuttlecocks. Sets up on any lawn or driveway in 3 minutes.",
        category: .sports,
        dailyRate: 0.0, // FREE Community Lend
        depositHold: 0.0,
        distanceMeters: 200.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 200m away",
        exactAddress: "68 Thurstan Road, Colombo 07",
        coordinate: Coordinate(latitude: 6.9058, longitude: 79.8693),
        lender: .anusha,
        systemImageName: "figure.badminton",
        imageURL: "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.91,
        coreMLTag: "Sports"
    )
    
    static let cricketKit = BorrowItem(
        id: UUID(uuidString: "aaaa6666-0006-0006-0006-000000000003")!,
        title: "English Willow Cricket Bat & Match Kit",
        description: "Full cricket kit including Grade 1 English Willow short-handle bat, 2 red four-piece leather balls, wooden spring stumps with bails, batting pads, and glove pair. Clean and oiled.",
        category: .sports,
        dailyRate: 1200.0,
        depositHold: 4000.0,
        distanceMeters: 340.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 340m away",
        exactAddress: "30 Cambridge Place, Colombo 07",
        coordinate: Coordinate(latitude: 6.9088, longitude: 79.8685),
        lender: .dilshan,
        systemImageName: "figure.cricket",
        imageURL: "https://images.unsplash.com/photo-1531415074868-036b1c57e329?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.96,
        coreMLTag: "Sports"
    )
    
    static let kayakSet = BorrowItem(
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        title: "Inflatable Kayak & Paddle Set",
        description: "Heavy-duty 1-person tandem-capable inflatable kayak with dual paddles, high-output hand pump, and adult life vest. Packs down cleanly into car trunk for Bolgoda or Kelani river excursions.",
        category: .sports,
        dailyRate: 3500.0,
        depositHold: 12000.0,
        distanceMeters: 480.0,
        rating: 4.9,
        isAvailable: true,
        isAvailableWeekend: true,
        pickupAddressSharedAfterApproval: true,
        approximateAddress: "Colombo 07 · 480m away",
        exactAddress: "89 Maitland Crescent, Colombo 07",
        coordinate: Coordinate(latitude: 6.9099, longitude: 79.8734),
        lender: .chamari,
        systemImageName: "figure.open.water.swim",
        imageURL: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.91,
        coreMLTag: "Sports"
    )
    
    // Backwards compatibility
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
        approximateAddress: "Colombo 07 · 170m away",
        exactAddress: "12 Maitland Place, Colombo 07",
        coordinate: Coordinate(latitude: 6.9068, longitude: 79.8722),
        lender: .chamari,
        systemImageName: "sparkles",
        imageURL: "https://images.unsplash.com/photo-1558317374-067fb5f30001?auto=format&fit=crop&w=800&q=80",
        coreMLConfidence: 0.94,
        coreMLTag: "Power Tools"
    )
    
    static let allSeedItems: [BorrowItem] = [
        // Kitchen (Free & Paid)
        coconutScraper,
        stringHopperPress,
        biryaniCauldron,
        mixerGrinder,
        standMixer,
        
        // Power Tools (Free & Paid)
        angleGrinder,
        rotaryHammerDrill,
        dewaltDrill,
        pressureWasher,
        circularSaw,
        
        // Hand Tools (Free & Paid)
        telescopingLadder,
        studFinderLevel,
        pipeWrenchSet,
        socketSet,
        
        // Garden & Yard (Free & Paid)
        gardenShears,
        wheelbarrowUdalla,
        brushCutter,
        gardenHoseSprinkler,
        
        // Camping & Outdoor (Free & Paid)
        campingStove,
        trailTent,
        campChairs,
        coolerBox,
        eventTableChairs,
        
        // Sports & Leisure (Free & Paid)
        carromBoard,
        badmintonSet,
        cricketKit,
        kayakSet
    ]
}
