import Foundation
import CoreData

// Core Data Offline Persistence Controller
public class PersistenceController {
    public static let shared = PersistenceController()
    
    public static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        // Seed preview objects if needed
        return controller
    }()
    
    public let container: NSPersistentContainer
    
    public init(inMemory: Bool = false) {
        // Construct programmatic managed object model to guarantee zero compilation errors
        let model = Self.createManagedObjectModel()
        container = NSPersistentContainer(name: "BorrowItModel", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load store: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Programmatic Core Data Schema: CachedItemEntity, CachedBorrowEntity, OfflineQRPassEntity
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // 1. CachedItemEntity
        let itemEntity = NSEntityDescription()
        itemEntity.name = "CachedItemEntity"
        itemEntity.managedObjectClassName = "CachedItemEntity"
        
        let itemIdAttr = NSAttributeDescription()
        itemIdAttr.name = "id"
        itemIdAttr.attributeType = .UUIDAttributeType
        itemIdAttr.isOptional = false
        
        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false
        
        let descAttr = NSAttributeDescription()
        descAttr.name = "itemDescription"
        descAttr.attributeType = .stringAttributeType
        descAttr.isOptional = true
        
        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isOptional = false
        
        let dailyRateAttr = NSAttributeDescription()
        dailyRateAttr.name = "dailyRate"
        dailyRateAttr.attributeType = .doubleAttributeType
        dailyRateAttr.defaultValue = 8.0
        
        let depositAttr = NSAttributeDescription()
        depositAttr.name = "depositHold"
        depositAttr.attributeType = .doubleAttributeType
        depositAttr.defaultValue = 40.0
        
        let distanceAttr = NSAttributeDescription()
        distanceAttr.name = "distanceMeters"
        distanceAttr.attributeType = .doubleAttributeType
        distanceAttr.defaultValue = 120.0
        
        let ratingAttr = NSAttributeDescription()
        ratingAttr.name = "rating"
        ratingAttr.attributeType = .doubleAttributeType
        ratingAttr.defaultValue = 4.9
        
        let isAvailableAttr = NSAttributeDescription()
        isAvailableAttr.name = "isAvailable"
        isAvailableAttr.attributeType = .booleanAttributeType
        isAvailableAttr.defaultValue = true
        
        let isFavoriteAttr = NSAttributeDescription()
        isFavoriteAttr.name = "isFavorite"
        isFavoriteAttr.attributeType = .booleanAttributeType
        isFavoriteAttr.defaultValue = false
        
        let exactAddrAttr = NSAttributeDescription()
        exactAddrAttr.name = "exactAddress"
        exactAddrAttr.attributeType = .stringAttributeType
        exactAddrAttr.isOptional = true
        
        let approxAddrAttr = NSAttributeDescription()
        approxAddrAttr.name = "approximateAddress"
        approxAddrAttr.attributeType = .stringAttributeType
        approxAddrAttr.isOptional = true
        
        let latAttr = NSAttributeDescription()
        latAttr.name = "latitude"
        latAttr.attributeType = .doubleAttributeType
        latAttr.defaultValue = 6.9064
        
        let lonAttr = NSAttributeDescription()
        lonAttr.name = "longitude"
        lonAttr.attributeType = .doubleAttributeType
        lonAttr.defaultValue = 79.8708
        
        let lenderNameAttr = NSAttributeDescription()
        lenderNameAttr.name = "lenderName"
        lenderNameAttr.attributeType = .stringAttributeType
        lenderNameAttr.isOptional = true
        
        let lenderInitialsAttr = NSAttributeDescription()
        lenderInitialsAttr.name = "lenderInitials"
        lenderInitialsAttr.attributeType = .stringAttributeType
        lenderInitialsAttr.isOptional = true
        
        let iconAttr = NSAttributeDescription()
        iconAttr.name = "systemImageName"
        iconAttr.attributeType = .stringAttributeType
        iconAttr.isOptional = true
        
        let coreMLTagAttr = NSAttributeDescription()
        coreMLTagAttr.name = "coreMLTag"
        coreMLTagAttr.attributeType = .stringAttributeType
        coreMLTagAttr.isOptional = true
        
        let imageURLAttr = NSAttributeDescription()
        imageURLAttr.name = "imageURL"
        imageURLAttr.attributeType = .stringAttributeType
        imageURLAttr.isOptional = true
        
        itemEntity.properties = [
            itemIdAttr, titleAttr, descAttr, categoryAttr, dailyRateAttr, depositAttr,
            distanceAttr, ratingAttr, isAvailableAttr, isFavoriteAttr, exactAddrAttr,
            approxAddrAttr, latAttr, lonAttr, lenderNameAttr, lenderInitialsAttr,
            iconAttr, coreMLTagAttr, imageURLAttr
        ]
        
        // 2. CachedBorrowEntity
        let borrowEntity = NSEntityDescription()
        borrowEntity.name = "CachedBorrowEntity"
        borrowEntity.managedObjectClassName = "CachedBorrowEntity"
        
        let borrowIdAttr = NSAttributeDescription()
        borrowIdAttr.name = "id"
        borrowIdAttr.attributeType = .UUIDAttributeType
        borrowIdAttr.isOptional = false
        
        let borrowItemIdAttr = NSAttributeDescription()
        borrowItemIdAttr.name = "itemId"
        borrowItemIdAttr.attributeType = .UUIDAttributeType
        borrowItemIdAttr.isOptional = false
        
        let stateAttr = NSAttributeDescription()
        stateAttr.name = "state"
        stateAttr.attributeType = .stringAttributeType
        stateAttr.isOptional = false
        
        let borrowerNameAttr = NSAttributeDescription()
        borrowerNameAttr.name = "borrowerName"
        borrowerNameAttr.attributeType = .stringAttributeType
        borrowerNameAttr.isOptional = true
        
        let tokenAttr = NSAttributeDescription()
        tokenAttr.name = "handoffToken"
        tokenAttr.attributeType = .stringAttributeType
        tokenAttr.isOptional = true
        
        let tokenExpAttr = NSAttributeDescription()
        tokenExpAttr.name = "handoffTokenExpiresAt"
        tokenExpAttr.attributeType = .dateAttributeType
        tokenExpAttr.isOptional = true
        
        let itemTitleAttr = NSAttributeDescription()
        itemTitleAttr.name = "itemTitle"
        itemTitleAttr.attributeType = .stringAttributeType
        itemTitleAttr.isOptional = true
        
        borrowEntity.properties = [
            borrowIdAttr, borrowItemIdAttr, stateAttr, borrowerNameAttr,
            tokenAttr, tokenExpAttr, itemTitleAttr
        ]
        
        // 3. OfflineQRPassEntity
        let passEntity = NSEntityDescription()
        passEntity.name = "OfflineQRPassEntity"
        passEntity.managedObjectClassName = "OfflineQRPassEntity"
        
        let passIdAttr = NSAttributeDescription()
        passIdAttr.name = "id"
        passIdAttr.attributeType = .UUIDAttributeType
        passIdAttr.isOptional = false
        
        let passBorrowIdAttr = NSAttributeDescription()
        passBorrowIdAttr.name = "borrowId"
        passBorrowIdAttr.attributeType = .UUIDAttributeType
        passBorrowIdAttr.isOptional = false
        
        let passTokenAttr = NSAttributeDescription()
        passTokenAttr.name = "token"
        passTokenAttr.attributeType = .stringAttributeType
        passTokenAttr.isOptional = false
        
        let payloadJSONAttr = NSAttributeDescription()
        payloadJSONAttr.name = "payloadJSON"
        payloadJSONAttr.attributeType = .stringAttributeType
        payloadJSONAttr.isOptional = false
        
        let passExpiresAtAttr = NSAttributeDescription()
        passExpiresAtAttr.name = "expiresAt"
        passExpiresAtAttr.attributeType = .dateAttributeType
        passExpiresAtAttr.isOptional = false
        
        passEntity.properties = [
            passIdAttr, passBorrowIdAttr, passTokenAttr, payloadJSONAttr, passExpiresAtAttr
        ]
        
        model.entities = [itemEntity, borrowEntity, passEntity]
        return model
    }
    
    public func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error.localizedDescription)")
            }
        }
    }
    
    // Offline QR Pass Caching
    public func cacheOfflineQRPass(payload: QRPayload) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "OfflineQRPassEntity")
        fetchRequest.predicate = NSPredicate(format: "borrowId == %@", payload.borrowId as CVarArg)
        
        if let existing = try? context.fetch(fetchRequest).first {
            existing.setValue(payload.rotatingToken, forKey: "token")
            existing.setValue(payload.toJSONString() ?? "", forKey: "payloadJSON")
            existing.setValue(Date().addingTimeInterval(300), forKey: "expiresAt")
        } else {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "OfflineQRPassEntity", into: context)
            entity.setValue(UUID(), forKey: "id")
            entity.setValue(payload.borrowId, forKey: "borrowId")
            entity.setValue(payload.rotatingToken, forKey: "token")
            entity.setValue(payload.toJSONString() ?? "", forKey: "payloadJSON")
            entity.setValue(Date().addingTimeInterval(300), forKey: "expiresAt")
        }
        saveContext()
    }
    
    public func fetchLatestOfflinePass(borrowId: UUID) -> QRPayload? {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "OfflineQRPassEntity")
        fetchRequest.predicate = NSPredicate(format: "borrowId == %@", borrowId as CVarArg)
        
        guard let object = try? context.fetch(fetchRequest).first,
              let json = object.value(forKey: "payloadJSON") as? String,
              let payload = try? QRPayload.from(jsonString: json) else {
            return nil
        }
        return payload
    }
}
