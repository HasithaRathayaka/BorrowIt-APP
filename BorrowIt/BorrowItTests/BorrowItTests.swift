import Foundation
import Testing
@testable import BorrowIt

//Swift Testing
@Suite("BorrowIt Core Logic & State Machine Tests")
struct BorrowItTests {

    // Test Valid Transitions
    @Test("Borrow lifecycle valid transitions: Pending -> Approved -> Handoff -> Borrowed -> Returned")
    func testValidBorrowLifecycleTransitions() throws {
        var transaction = BorrowTransaction(
            item: .dewaltDrill,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            state: .pending
        )
        #expect(transaction.state == .pending)
        #expect(transaction.state.timelineStepIndex == 1)
        
        try transaction.transition(to: .approved)
        #expect(transaction.state == .approved)
        #expect(transaction.state.timelineStepIndex == 2)
        
        // Handoff within 50m geofence
        try transaction.transition(to: .handoff)
        #expect(transaction.state == .handoff)
        
        // Vision QR verification
        try transaction.transition(to: .borrowed)
        #expect(transaction.state == .borrowed)
        #expect(transaction.pickedUpAt != nil)
        #expect(transaction.state.timelineStepIndex == 3)
        
        // Return QR verification
        try transaction.transition(to: .returned)
        #expect(transaction.state == .returned)
        #expect(transaction.returnedAt != nil)
        #expect(transaction.state.timelineStepIndex == 4)
    }

    // Invalid Transitions Rejected
    @Test("Invalid borrow state transitions are rejected with BorrowStateError.invalidTransition")
    func testInvalidBorrowTransitionsAreRejected() {
        var pendingTransaction = BorrowTransaction(item: .dewaltDrill, state: .pending)
        
        // Cannot jump directly from Pending to Returned
        #expect(throws: BorrowStateError.invalidTransition(from: .pending, to: .returned)) {
            try pendingTransaction.transition(to: .returned)
        }
        
        // Cannot jump directly from Pending to Borrowed without Lender Approval
        #expect(throws: BorrowStateError.invalidTransition(from: .pending, to: .borrowed)) {
            try pendingTransaction.transition(to: .borrowed)
        }
        
        var returnedTransaction = BorrowTransaction(item: .dewaltDrill, state: .returned)
        // Cannot transition anywhere once Returned
        #expect(throws: BorrowStateError.invalidTransition(from: .returned, to: .borrowed)) {
            try returnedTransaction.transition(to: .borrowed)
        }
    }

    // Price, Duration and Deposit Calculation
    @Test("Borrow price, duration, and refundable deposit calculation")
    func testBorrowCostAndDepositCalculations() {
        let dailyRate = 1500.0
        let deposit = 5000.0
        let days = 3
        
        let calculation = BorrowTransaction.calculateCost(days: days, rate: dailyRate, deposit: deposit)
        
        #expect(calculation.rentalCost == 4500.0) // 3 * Rs. 1500 = Rs. 4500
        #expect(calculation.depositHold == 5000.0) // Rs. 5000 hold
        #expect(calculation.grandTotal == 9500.0)  // Rs. 4500 + Rs. 5000 = Rs. 9500
        
        // Verify multi day calculation on Transaction model
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 5, to: start)!
        let tx = BorrowTransaction(item: .standMixer, startDate: start, endDate: end)
        
        #expect(tx.totalDays == 5)
        #expect(tx.totalRentalCost == 10000.0) // 5 days * Rs. 2000/day
        #expect(tx.depositHoldAmount == 12000.0)
    }

    // Explore Filter Logic Radius and Categories
    @Test("Explore filter logic: radius slider (500m) and category filtering")
    @MainActor
    func testExploreViewModelFilters() async {
        let mockService = MockBackendService(items: BorrowItem.allSeedItems)
        let vm = ExploreViewModel(backendService: mockService)
        await vm.fetchItems()
        
        #expect(vm.items.count == BorrowItem.allSeedItems.count)
        
        // 1. Filter by 500m radius
        vm.searchRadiusMeters = 500.0
        #expect(vm.filteredItems.allSatisfy { $0.distanceMeters <= 500.0 })
        
        // 2. Filter by 200m radius
        vm.searchRadiusMeters = 200.0
        #expect(vm.filteredItems.allSatisfy { $0.distanceMeters <= 200.0 })
        #expect(vm.filteredItems.contains(where: { $0.title.contains("Drill") }))
        
        // 3. Filter by Category Chip
        vm.searchRadiusMeters = 1000.0
        vm.selectedCategory = .camping
        #expect(vm.filteredItems.allSatisfy { $0.category == .camping })
        
        // 4. Filter by Free Items Only
        vm.selectedCategory = nil
        vm.filterFreeOnly = true
        #expect(vm.filteredItems.allSatisfy { $0.isFree })
        
        // 5. Search query filter
        vm.filterFreeOnly = false
        vm.searchQuery = "DeWalt"
        #expect(vm.filteredCount >= 1)
        #expect(vm.filteredItems.first?.title.contains("DeWalt") == true)
    }

    // Core ML and Vision Taxonomy Mapping
    @Test("On-device Core ML & Vision category classifier mapping")
    func testClassifierCategoryMapping() {
        let classifier = ImageClassifierService.shared
        
        // Power Tools
        #expect(classifier.mapLabelToCategory("power_drill, hammer_drill") == .powerTools)
        #expect(classifier.mapLabelToCategory("circular_saw, blade") == .powerTools)
        
        // Hand Tools
        #expect(classifier.mapLabelToCategory("claw_hammer, tool") == .handTools)
        #expect(classifier.mapLabelToCategory("adjustable_wrench, spanner") == .handTools)
        
        // Camping
        #expect(classifier.mapLabelToCategory("mountain_tent, dome_tent") == .camping)
        #expect(classifier.mapLabelToCategory("backpacking_stove, camping") == .camping)
        
        // Garden
        #expect(classifier.mapLabelToCategory("lawn_mower, grass") == .garden)
        #expect(classifier.mapLabelToCategory("hedge_pruner, shears") == .garden)
        
        // Kitchen
        #expect(classifier.mapLabelToCategory("stand_mixer, dough_hook") == .kitchen)
        #expect(classifier.mapLabelToCategory("espresso_maker, coffee") == .kitchen)
        
        // Sports
        #expect(classifier.mapLabelToCategory("inflatable_kayak, paddle") == .sports)
    }

    // Rotating QR Pass Token and Expiration Validation
    @Test("QR Handoff token generation, Vision decoding, and expiration validation")
    func testQRPayloadGenerationAndExpiration() throws {
        let borrowId = UUID()
        let borrowerId = UUID()
        
        let freshPayload = QRPayload(
            borrowId: borrowId,
            borrowerId: borrowerId,
            borrowerName: "Alex Morgan",
            action: .pickup,
            timestamp: Date(),
            rotatingToken: "PASS-7721"
        )
        
        let jsonString = freshPayload.toJSONString()
        #expect(jsonString != nil)
        
        let decoded = try QRPayload.from(jsonString: jsonString!)
        #expect(decoded.borrowId == borrowId)
        #expect(decoded.rotatingToken == "PASS-7721")
        #expect(decoded.action == .pickup)
        
        #expect(freshPayload.isValid(windowSeconds: 300) == true)
        
        let expiredPayload = QRPayload(
            borrowId: borrowId,
            borrowerId: borrowerId,
            borrowerName: "Alex Morgan",
            action: .pickup,
            timestamp: Date().addingTimeInterval(-600), // 10 minutes old
            rotatingToken: "STALE-0000"
        )
        #expect(expiredPayload.isValid(windowSeconds: 300) == false)
    }

    // Protocol Oriented DI with MockBackendService
    @Test("Protocol-Oriented Dependency Injection with MockBackendService")
    @MainActor
    func testProtocolOrientedDependencyInjection() async throws {
        let customMock = MockBackendService()
        
        // Injected into ExploreViewModel
        let exploreVM = ExploreViewModel(backendService: customMock)
        await exploreVM.fetchItems()
        #expect(exploreVM.items.count == BorrowItem.allSeedItems.count)
        
        // Test adding item through protocol
        let newItem = BorrowItem(
            title: "Test Injected Ladder",
            description: "12ft aluminum step ladder",
            category: .handTools,
            dailyRate: 7.0,
            depositHold: 30.0,
            distanceMeters: 90.0,
            coordinate: Coordinate(latitude: 6.9070, longitude: 79.8713),
            lender: .maya,
            systemImageName: "ladder"
        )
        _ = try await customMock.addItem(newItem)
        await exploreVM.fetchItems()
        #expect(exploreVM.items.contains(where: { $0.title == "Test Injected Ladder" }))
    }
    
    // Free Community Lending
    @Test("Community free lending items have zero daily rate and correct rate formatting")
    func testFreeCommunityLending() {
        let freeLadder = BorrowItem.telescopingLadder
        #expect(freeLadder.isFree)
        #expect(freeLadder.formattedRate == "Free")
        
        let paidDrill = BorrowItem.dewaltDrill
        #expect(!paidDrill.isFree)
        #expect(paidDrill.formattedRate.contains("Rs."))
    }
    
    // Explore Mode Reset to Feed
    @Test("ExploreViewModel resets cleanly to Feed mode from Map mode and clears preview/detail")
    @MainActor
    func testResetToFeed() {
        let vm = ExploreViewModel(backendService: MockBackendService())
        vm.isFeedMode = false
        vm.selectedItemForMapPreview = BorrowItem.dewaltDrill
        vm.selectedItemForDetail = BorrowItem.dewaltDrill
        
        #expect(!vm.isFeedMode)
        #expect(vm.selectedItemForMapPreview != nil)
        #expect(vm.selectedItemForDetail != nil)
        
        vm.resetToFeed()
        
        #expect(vm.isFeedMode)
        #expect(vm.selectedItemForMapPreview == nil)
        #expect(vm.selectedItemForDetail == nil)
    }

    // Face ID Biometric Gate and App Lock State Machine
    @Test("Face ID security gate: lifecycle app lock, biometric authentication, and lock/unlock transitions")
    @MainActor
    func testFaceIDBiometricLockAndUnlock() async {
        let mockBio = MockBiometricService()
        let authVM = AuthViewModel(biometricService: mockBio, backendService: MockBackendService())
        let settings = AppSettingsManager()
        
        // App starts unlocked
        settings.isAppLocked = false
        #expect(!settings.isAppLocked)
        
        // Minimizing or backgrounding the app locks it
        settings.lockAppWithFaceID()
        #expect(settings.isAppLocked)
        
        // Successful Face ID verification unlocks the app
        mockBio.shouldSucceed = true
        let unlockSuccess = await authVM.authenticateWithBiometrics(reason: "Unlock BorrowIt Test")
        #expect(unlockSuccess == true)
        #expect(authVM.authErrorMessage == nil)
        #expect(mockBio.lastReasonPrompt == "Unlock BorrowIt Test")
        
        // Unlock state transition
        settings.unlockApp()
        #expect(!settings.isAppLocked)
        
        // Failed Face ID verification keeps the app securely locked
        settings.lockAppWithFaceID()
        #expect(settings.isAppLocked)
        
        mockBio.shouldSucceed = false
        let failSuccess = await authVM.authenticateWithBiometrics(reason: "Unlock BorrowIt Test Fail")
        #expect(failSuccess == false)
        #expect(authVM.authErrorMessage != nil)
        #expect(settings.isAppLocked) // Privacy shield remains locked
        
        // Native Biometric Service properties
        #expect(mockBio.biometricTypeString == "Face ID")
        #expect(mockBio.isBiometricsAvailable == true)
    }
}

// Mock Biometric Service for Unit Testing
private class MockBiometricService: BiometricServiceProtocol {
    var shouldSucceed: Bool = true
    var isBiometricsAvailable: Bool = true
    var biometricTypeString: String = "Face ID"
    var lastReasonPrompt: String? = nil
    
    func authenticate(reason: String) async -> Result<Bool, Error> {
        self.lastReasonPrompt = reason
        if shouldSucceed {
            return .success(true)
        } else {
            let error = NSError(
                domain: "com.borrowit.tests",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Face ID recognition failed. Try again."]
            )
            return .failure(error)
        }
    }
}


