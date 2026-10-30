import SwiftUI
import Combine

// Explore Dashboard ViewModel
@MainActor
public class ExploreViewModel: ObservableObject {
    @Published public var items: [BorrowItem] = []
    @Published public var searchQuery: String = ""
    @Published public var selectedCategory: ItemCategory? = nil // nil means "All nearby"
    @Published public var searchRadiusMeters: Double = AppConfig.defaultSearchRadiusMeters
    @Published public var filterWeekendOnly: Bool = false
    @Published public var filterFreeOnly: Bool = false
    @Published public var selectedFilterCategories: Set<ItemCategory> = []
    
    @Published public var isFeedMode: Bool = true // true = Feed List, false = Map Mode
    @Published public var selectedItemForMapPreview: BorrowItem? = nil
    @Published public var selectedItemForDetail: BorrowItem? = nil
    @Published public var isFilterSheetPresented: Bool = false
    @Published public var isAddItemPresented: Bool = false
    @Published public var isLoading: Bool = false
    
    private let backendService: BackendServiceProtocol
    
    public init(backendService: BackendServiceProtocol = SupabaseService.shared) {
        self.backendService = backendService
        Task {
            await fetchItems()
        }
    }
    
    // Filtering Logic
    public var filteredItems: [BorrowItem] {
        items.filter { item in
            // Search text match (title, description, lender)
            let matchesSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchQuery) ||
                item.description.localizedCaseInsensitiveContains(searchQuery) ||
                item.lender.name.localizedCaseInsensitiveContains(searchQuery)
            
            // Category chip match
            let matchesChip = (selectedCategory == nil) || (item.category == selectedCategory)
            
            // Sheet category multi-select match
            let matchesSheetCategories = selectedFilterCategories.isEmpty || selectedFilterCategories.contains(item.category)
            
            // Radius match
            let matchesRadius = item.distanceMeters <= searchRadiusMeters
            
            // Weekend filter match
            let matchesWeekend = !filterWeekendOnly || item.isAvailableWeekend
            
            // Free items filter match
            let matchesFree = !filterFreeOnly || item.isFree
            
            return matchesSearch && matchesChip && matchesSheetCategories && matchesRadius && matchesWeekend && matchesFree
        }
    }
    
    public var filteredCount: Int {
        filteredItems.count
    }
    
    // Actions
    public func fetchItems() async {
        isLoading = true
        do {
            self.items = try await backendService.fetchItems()
            // Set default selected item for map preview
            if selectedItemForMapPreview == nil {
                selectedItemForMapPreview = items.first
            }
        } catch {
            print("Failed to fetch items: \(error)")
        }
        isLoading = false
    }
    
    public func toggleFavorite(for item: BorrowItem) {
        Task {
            let newState = try? await backendService.toggleFavorite(itemId: item.id)
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].isFavorite = newState ?? !items[idx].isFavorite
            }
        }
    }
    
    public func resetFilters() {
        searchQuery = ""
        selectedCategory = nil
        searchRadiusMeters = AppConfig.defaultSearchRadiusMeters
        filterWeekendOnly = false
        filterFreeOnly = false
        selectedFilterCategories.removeAll()
    }
    
    public func expandRadiusTo1000m() {
        searchRadiusMeters = 1000.0
    }
    
    // User's Uploaded / Listed Items Management
    public func myListedItems(for user: UserProfile) -> [BorrowItem] {
        items.filter { item in
            item.lender.id == user.id ||
            item.lender.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == user.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
    
    public func toggleItemAvailability(for item: BorrowItem) {
        Task {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].isAvailable.toggle()
                let updated = items[idx]
                _ = try? await backendService.updateItem(updated)
            }
        }
    }
    
    public func updateItem(_ item: BorrowItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.insert(item, at: 0)
        }
    }
    
    public func deleteItem(_ item: BorrowItem) {
        Task {
            items.removeAll(where: { $0.id == item.id })
            try? await backendService.deleteItem(id: item.id)
        }
    }
    
    // Navigation and Mode Reset
    /// Directly switches to Feed mode and dismisses any active map pin preview card or pushed detail view.
    public func resetToFeed() {
        isFeedMode = true
        selectedItemForMapPreview = nil
        selectedItemForDetail = nil
    }
}

