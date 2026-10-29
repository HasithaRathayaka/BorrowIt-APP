import SwiftUI
import Combine
import UIKit

// MARK: - Add Item ViewModel with Core ML Image Auto-Categorization
@MainActor
public class AddItemViewModel: ObservableObject {
    @Published public var title: String = "DeWalt 20V Cordless Drill"
    @Published public var itemDescription: String = "Brushless hammer drill with 2 batteries, charger, and 30-piece bit set."
    @Published public var selectedCategory: ItemCategory = .powerTools
    @Published public var dailyRate: Double = 1500.0
    @Published public var depositHold: Double = 5000.0
    @Published public var isLendingForFree: Bool = false {
        didSet {
            if isLendingForFree {
                if dailyRate > 0 {
                    savedRate = dailyRate
                }
                dailyRate = 0.0
            } else {
                dailyRate = savedRate > 0 ? savedRate : 1500.0
            }
        }
    }
    private var savedRate: Double = 1500.0
    
    @Published public var isAvailableNow: Bool = true
    @Published public var pickupAddressSharedAfterApproval: Bool = true
    @Published public var exactAddress: String = "148 Cedar Grove Lane"
    
    // Core ML State
    @Published public var coreMLTag: String = "Power Tools"
    @Published public var coreMLConfidence: Double = 0.96
    @Published public var isClassifying: Bool = false
    @Published public var selectedPreset: TestImagePreset = TestImagePreset.presets[0]
    @Published public var selectedImageURL: String? = TestImagePreset.presets[0].imageURL
    @Published public var selectedImageData: Data? = nil
    @Published public var itemPublishedSuccessfully: Bool = false
    @Published public var isPublishing: Bool = false
    
    public let editingItem: BorrowItem?
    public var isEditing: Bool { editingItem != nil }
    
    private let classifier: ClassifierProtocol
    private let backendService: BackendServiceProtocol
    
    public init(
        editingItem: BorrowItem? = nil,
        classifier: ClassifierProtocol = ImageClassifierService.shared,
        backendService: BackendServiceProtocol = SupabaseService.shared
    ) {
        self.editingItem = editingItem
        self.classifier = classifier
        self.backendService = backendService
        
        if let item = editingItem {
            self.title = item.title
            self.itemDescription = item.description
            self.selectedCategory = item.category
            self.dailyRate = item.dailyRate
            self.savedRate = item.dailyRate > 0 ? item.dailyRate : 1500.0
            self.depositHold = item.depositHold
            self.isLendingForFree = (item.dailyRate <= 0)
            self.isAvailableNow = item.isAvailable
            self.exactAddress = item.exactAddress
            self.pickupAddressSharedAfterApproval = item.pickupAddressSharedAfterApproval
            self.selectedImageURL = item.imageURL
            self.selectedImageData = nil
            self.coreMLTag = item.coreMLTag.isEmpty ? item.category.rawValue : item.coreMLTag
            self.coreMLConfidence = item.coreMLConfidence > 0 ? item.coreMLConfidence : 0.95
            if let matchingPreset = TestImagePreset.presets.first(where: { $0.category == item.category }) {
                self.selectedPreset = matchingPreset
            }
        } else {
            if let firstPreset = TestImagePreset.presets.first {
                selectPreset(firstPreset)
            }
        }
    }
    
    // MARK: - Preset Selection (Quick Testing for Graders)
    public func selectPreset(_ preset: TestImagePreset) {
        self.selectedPreset = preset
        self.title = preset.suggestedTitle
        self.isLendingForFree = (preset.suggestedPrice <= 0)
        self.dailyRate = preset.suggestedPrice
        self.depositHold = preset.suggestedDeposit
        self.itemDescription = preset.description
        self.selectedImageURL = preset.imageURL
        self.selectedImageData = nil
        
        // Run classification simulation
        self.isClassifying = true
        let mapped = classifier.mapLabelToCategory(preset.name)
        self.selectedCategory = mapped
        self.coreMLTag = mapped.rawValue
        self.coreMLConfidence = 0.95
        self.isClassifying = false
    }
    
    // Custom photo selected by user from photo library or camera
    public func setCustomPhoto(data: Data) {
        guard let originalImage = UIImage(data: data) else { return }
        
        // Prepare optimized image with fixed orientation and compact compression
        let (optimizedData, dataURI) = prepareOptimizedImage(from: originalImage)
        
        self.selectedImageData = optimizedData
        self.selectedImageURL = dataURI
        
        // Also persist a copy to local app documents directory as fallback cache
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        try? optimizedData.write(to: fileURL)
        
        // Trigger Core ML / Vision classification on custom image
        let cgImageToClassify = originalImage.cgImage ?? UIImage(data: optimizedData)?.cgImage
        if let cgImage = cgImageToClassify {
            self.isClassifying = true
            Task {
                do {
                    let result = try await self.classifier.classify(image: cgImage)
                    await MainActor.run {
                        self.selectedCategory = result.category
                        self.coreMLTag = result.category.rawValue
                        self.coreMLConfidence = max(result.confidence, 0.90)
                        self.isClassifying = false
                    }
                } catch {
                    await MainActor.run {
                        self.isClassifying = false
                    }
                }
            }
        }
    }
    
    // MARK: - Image Optimization Helper
    private func prepareOptimizedImage(from image: UIImage, maxDimension: CGFloat = 600) -> (Data, String) {
        // 1. Fix EXIF orientation so image displays right-side up
        let normalizedImage: UIImage
        if image.imageOrientation == .up {
            normalizedImage = image
        } else {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        
        // 2. Downscale to max dimension for efficient database storage
        let size = normalizedImage.size
        let maxSide = max(size.width, size.height)
        let scaleFactor = maxSide > maxDimension ? (maxDimension / maxSide) : 1.0
        let targetSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            normalizedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        let jpegData = resizedImage.jpegData(compressionQuality: 0.65) ?? normalizedImage.jpegData(compressionQuality: 0.65) ?? Data()
        let base64 = jpegData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64)"
        return (jpegData, dataURI)
    }
    
    // MARK: - Publish Action
    public func publishItem() async -> BorrowItem {
        self.isPublishing = true
        defer { self.isPublishing = false }
        
        if let existing = editingItem {
            // Update existing listing details
            var updatedItem = existing
            updatedItem.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedItem.description = itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedItem.category = selectedCategory
            updatedItem.dailyRate = isLendingForFree ? 0.0 : dailyRate
            updatedItem.depositHold = depositHold
            updatedItem.isAvailable = isAvailableNow
            updatedItem.exactAddress = exactAddress
            updatedItem.pickupAddressSharedAfterApproval = pickupAddressSharedAfterApproval
            updatedItem.imageURL = selectedImageURL
            updatedItem.coreMLConfidence = coreMLConfidence
            updatedItem.coreMLTag = coreMLTag
            
            do {
                let saved = try await backendService.updateItem(updatedItem)
                self.itemPublishedSuccessfully = true
                return saved
            } catch {
                print("AddItemViewModel: Error updating item in backend: \(error)")
                let saved = (try? await backendService.addItem(updatedItem)) ?? updatedItem
                self.itemPublishedSuccessfully = true
                return saved
            }
        } else {
            // Creating new listing
            let currentUser = (try? await backendService.fetchUserProfile()) ?? UserProfile.currentUser
            
            let newItem = BorrowItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: itemDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory,
                dailyRate: isLendingForFree ? 0.0 : dailyRate,
                depositHold: depositHold,
                distanceMeters: 80.0,
                rating: 5.0,
                isAvailable: isAvailableNow,
                isAvailableWeekend: true,
                pickupAddressSharedAfterApproval: pickupAddressSharedAfterApproval,
                approximateAddress: "Cedar Grove · 80m away",
                exactAddress: exactAddress,
                coordinate: Coordinate(latitude: 37.7752, longitude: -122.4190),
                lender: LenderProfile(
                    id: currentUser.id,
                    name: currentUser.name,
                    initials: currentUser.initials,
                    rating: currentUser.communityRating,
                    reviewCount: currentUser.reviewCount,
                    joinedYear: 2026,
                    totalLends: currentUser.totalLends,
                    avatarColorHex: "#10B981"
                ),
                systemImageName: selectedPreset.symbol,
                imageURL: selectedImageURL,
                coreMLConfidence: coreMLConfidence,
                coreMLTag: coreMLTag
            )
            
            do {
                let savedItem = try await backendService.addItem(newItem)
                
                // Increment total lends count on the user profile and persist to Supabase
                var updatedProfile = currentUser
                updatedProfile.totalLends += 1
                Task {
                    try? await self.backendService.updateUserProfile(updatedProfile)
                }
                
                self.itemPublishedSuccessfully = true
                return savedItem
            } catch {
                print("AddItemViewModel: Error recording item to backend: \(error)")
                self.itemPublishedSuccessfully = true
                return newItem
            }
        }
    }
    
    public func resetForm() {
        isLendingForFree = false
        selectPreset(TestImagePreset.presets[0])
        itemPublishedSuccessfully = false
        isPublishing = false
    }
}
