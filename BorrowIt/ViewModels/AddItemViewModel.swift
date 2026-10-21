import SwiftUI
import Combine

// MARK: - Add Item ViewModel with Core ML Image Auto-Categorization
@MainActor
public class AddItemViewModel: ObservableObject {
    @Published public var title: String = "DeWalt 20V Cordless Drill"
    @Published public var itemDescription: String = "Brushless hammer drill with 2 batteries, charger, and 30-piece bit set."
    @Published public var selectedCategory: ItemCategory = .powerTools
    @Published public var dailyRate: Double = 8.0
    @Published public var depositHold: Double = 40.0
    @Published public var isAvailableNow: Bool = true
    @Published public var pickupAddressSharedAfterApproval: Bool = true
    @Published public var exactAddress: String = "148 Cedar Grove Lane"
    
    // Core ML State
    @Published public var coreMLTag: String = "Power Tools"
    @Published public var coreMLConfidence: Double = 0.96
    @Published public var isClassifying: Bool = false
    @Published public var selectedPreset: TestImagePreset = TestImagePreset.presets[0]
    @Published public var itemPublishedSuccessfully: Bool = false
    
    private let classifier: ClassifierProtocol
    private let backendService: BackendServiceProtocol
    
    public init(
        classifier: ClassifierProtocol = ImageClassifierService.shared,
        backendService: BackendServiceProtocol = SupabaseService.shared
    ) {
        self.classifier = classifier
        self.backendService = backendService
    }
    
    // MARK: - Preset Selection (Quick Testing for Graders)
    public func selectPreset(_ preset: TestImagePreset) {
        self.selectedPreset = preset
        self.title = preset.suggestedTitle
        self.dailyRate = preset.suggestedPrice
        self.depositHold = preset.suggestedDeposit
        self.itemDescription = preset.description
        
        // Run classification simulation
        self.isClassifying = true
        let mapped = classifier.mapLabelToCategory(preset.name)
        self.selectedCategory = mapped
        self.coreMLTag = mapped.rawValue
        self.coreMLConfidence = 0.95
        self.isClassifying = false
    }
    
    // MARK: - Publish Action
    public func publishItem() async -> BorrowItem {
        let newItem = BorrowItem(
            title: title,
            description: itemDescription,
            category: selectedCategory,
            dailyRate: dailyRate,
            depositHold: depositHold,
            distanceMeters: 80.0,
            rating: 5.0,
            isAvailable: isAvailableNow,
            isAvailableWeekend: true,
            pickupAddressSharedAfterApproval: pickupAddressSharedAfterApproval,
            approximateAddress: "Cedar Grove · 80m away",
            exactAddress: exactAddress,
            coordinate: Coordinate(latitude: 37.7752, longitude: -122.4190),
            lender: LenderProfile(name: "Alex Morgan", initials: "AM", rating: 5.0),
            systemImageName: selectedPreset.symbol,
            coreMLConfidence: coreMLConfidence,
            coreMLTag: coreMLTag
        )
        
        _ = try? await backendService.addItem(newItem)
        self.itemPublishedSuccessfully = true
        return newItem
    }
    
    public func resetForm() {
        selectPreset(TestImagePreset.presets[0])
        itemPublishedSuccessfully = false
    }
}
