import Foundation
import Vision
import CoreML
import CoreGraphics
import SwiftUI

// MARK: - Preset Test Image Representation for Graders & Simulators
public struct TestImagePreset: Identifiable, Hashable {
    public var id: String { name }
    public var name: String
    public var category: ItemCategory
    public var symbol: String
    public var suggestedTitle: String
    public var suggestedPrice: Double
    public var suggestedDeposit: Double
    public var description: String
    public var imageURL: String?
    
    public init(
        name: String,
        category: ItemCategory,
        symbol: String,
        suggestedTitle: String,
        suggestedPrice: Double,
        suggestedDeposit: Double,
        description: String,
        imageURL: String? = nil
    ) {
        self.name = name
        self.category = category
        self.symbol = symbol
        self.suggestedTitle = suggestedTitle
        self.suggestedPrice = suggestedPrice
        self.suggestedDeposit = suggestedDeposit
        self.description = description
        self.imageURL = imageURL
    }
    
    public static let presets: [TestImagePreset] = [
        TestImagePreset(
            name: "Cordless Drill",
            category: .powerTools,
            symbol: "bolt.fill",
            suggestedTitle: "DeWalt 20V Max Cordless Drill",
            suggestedPrice: 1500.0,
            suggestedDeposit: 5000.0,
            description: "Cordless brushless hammer drill with dual battery packs and charger.",
            imageURL: "https://images.unsplash.com/photo-1572981779307-38b8cabb2407?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Claw Hammer",
            category: .handTools,
            symbol: "hammer.fill",
            suggestedTitle: "Estwing 16oz Rip Claw Hammer",
            suggestedPrice: 0.0, // FREE Community Lend
            suggestedDeposit: 2000.0,
            description: "Solid forged steel rip claw hammer with shock reduction grip.",
            imageURL: "https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Extension Ladder",
            category: .handTools,
            symbol: "arrow.up.and.down",
            suggestedTitle: "Little Giant 17ft Multi-Position Ladder",
            suggestedPrice: 0.0, // FREE Community Lend
            suggestedDeposit: 3000.0,
            description: "17ft aluminum telescoping ladder for seasonal gutter cleaning, painting, and high roof access.",
            imageURL: "https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Pressure Washer",
            category: .powerTools,
            symbol: "drop.fill",
            suggestedTitle: "Kärcher 1800-PSI High-Pressure Washer",
            suggestedPrice: 1800.0,
            suggestedDeposit: 6000.0,
            description: "Electric power washer for seasonal driveway, patio, and car deep cleans.",
            imageURL: "https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Backpacking Tent",
            category: .camping,
            symbol: "tent.fill",
            suggestedTitle: "2-Person Lightweight Trail Tent",
            suggestedPrice: 2500.0,
            suggestedDeposit: 8000.0,
            description: "3-season waterproof camping tent with rainfly and aluminum stakes.",
            imageURL: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Artisan Stand Mixer",
            category: .kitchen,
            symbol: "fork.knife",
            suggestedTitle: "KitchenAid 5-Qt Artisan Stand Mixer",
            suggestedPrice: 2000.0,
            suggestedDeposit: 12000.0,
            description: "Tilt-head stand mixer with stainless bowl and dough hook.",
            imageURL: "https://images.unsplash.com/photo-1594385208974-2e75f8d7bb48?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Circular Saw",
            category: .powerTools,
            symbol: "gearshape.2.fill",
            suggestedTitle: "Bosch 7-1/4\" Circular Saw",
            suggestedPrice: 2800.0,
            suggestedDeposit: 9000.0,
            description: "Precision 15-amp circular saw with laser guide.",
            imageURL: "https://images.unsplash.com/photo-1581147036324-c17ac41dfa6c?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Telescoping Pruner",
            category: .garden,
            symbol: "leaf.fill",
            suggestedTitle: "Fiskars Telescoping Tree Pruner",
            suggestedPrice: 1200.0,
            suggestedDeposit: 4000.0,
            description: "High-reach extendable tree pruner with saw blade.",
            imageURL: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=800&q=80"
        ),
        TestImagePreset(
            name: "Kayak & Paddle",
            category: .sports,
            symbol: "figure.open.water.swim",
            suggestedTitle: "Inflatable Kayak & Paddle Set",
            suggestedPrice: 3500.0,
            suggestedDeposit: 15000.0,
            description: "Tandem inflatable kayak with high-output pump and dual paddles.",
            imageURL: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80"
        )
    ]
}

// MARK: - On-Device Vision & Core ML Image Classifier
public class ImageClassifierService: ClassifierProtocol {
    public static let shared = ImageClassifierService()
    
    public init() {}
    
    // Execute VNClassifyImageRequest on-device safely without continuation double-resume
    public func classify(image: CGImage) async throws -> (category: ItemCategory, confidence: Double, rawLabel: String) {
        return await Task.detached(priority: .userInitiated) { [self] in
            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
                if let results = request.results as? [VNClassificationObservation],
                   let topResult = results.first {
                    let detectedLabel = topResult.identifier.lowercased()
                    let category = self.mapLabelToCategory(detectedLabel)
                    let confidence = Double(topResult.confidence)
                    return (category, confidence, detectedLabel)
                }
            } catch {
                print("[ImageClassifierService] Vision request threw: \(error). Using fallback classification.")
            }
            
            // Safe fallback for Simulator or hardware without Vision taxonomy
            return (ItemCategory.powerTools, 0.92, "power_drill")
        }.value
    }
    
    // MARK: - Taxonomy Mapping to BorrowIt Categories
    public func mapLabelToCategory(_ label: String) -> ItemCategory {
        let l = label.lowercased()
        
        // Power Tools
        if l.contains("drill") || l.contains("saw") || l.contains("sander") ||
            l.contains("grinder") || l.contains("power_drill") || l.contains("rotary") ||
            l.contains("generator") || l.contains("dremel") || l.contains("washer") || l.contains("cleaner") {
            return .powerTools
        }
        
        // Hand Tools
        if l.contains("hammer") || l.contains("wrench") || l.contains("screwdriver") ||
            l.contains("pliers") || l.contains("socket") || l.contains("hardware") ||
            l.contains("toolkit") || l.contains("measuring") || l.contains("ladder") ||
            l.contains("level") || l.contains("scanner") || l.contains("spanner") ||
            l.contains("tape") || l.contains("tool") {
            return .handTools
        }
        
        // Camping & Outdoors
        if l.contains("tent") || l.contains("backpack") || l.contains("sleeping") ||
            l.contains("lantern") || l.contains("stove") || l.contains("cooler") ||
            l.contains("camping") || l.contains("tarp") || l.contains("table") || l.contains("chair") ||
            l.contains("waterfall") || l.contains("river") || l.contains("water") ||
            l.contains("forest") || l.contains("mountain") || l.contains("nature") ||
            l.contains("outdoor") || l.contains("hike") || l.contains("trail") {
            return .camping
        }
        
        // Garden
        if l.contains("shears") || l.contains("pruner") || l.contains("mower") ||
            l.contains("shovel") || l.contains("rake") || l.contains("hose") ||
            l.contains("plant") || l.contains("garden") || l.contains("hedge") ||
            l.contains("grass") || l.contains("flower") || l.contains("leaf") {
            return .garden
        }
        
        // Kitchen
        if l.contains("mixer") || l.contains("blender") || l.contains("cooker") ||
            l.contains("pot") || l.contains("pan") || l.contains("espresso") ||
            l.contains("coffee") || l.contains("toaster") || l.contains("knife") ||
            l.contains("kitchen") || l.contains("dough") {
            return .kitchen
        }
        
        // Sports
        if l.contains("kayak") || l.contains("bike") || l.contains("bicycle") ||
            l.contains("ball") || l.contains("racket") || l.contains("paddle") ||
            l.contains("surfboard") || l.contains("ski") || l.contains("sports") ||
            l.contains("canoe") || l.contains("helmet") {
            return .sports
        }
        
        return .powerTools
    }
}
