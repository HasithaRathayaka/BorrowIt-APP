import Foundation

public struct AppConfig {
    // Supabase backend configuration (fallback to local seed if credentials default)
    public static let supabaseURL = URL(string: "https://xyzcompany.supabase.co")!
    public static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_anon_key_for_offline_demo"
    
    // Shared App Group for WidgetKit & AppIntents
    public static let appGroupIdentifier = "group.com.borrowit.shared"
    
    // Cedar Grove Neighborhood Default Center (San Francisco walkable reference)
    public static let cedarGroveCenter = Coordinate(latitude: 37.7749, longitude: -122.4194)
    public static let defaultSearchRadiusMeters: Double = 500.0
    public static let geofenceArrivalRadiusMeters: Double = 50.0
    public static let qrTokenExpirationSeconds: TimeInterval = 300.0 // 5 minutes
    
    // Runtime Mode Check
    public static var isSupabaseConfigured: Bool {
        let key = supabaseAnonKey
        return !key.contains("dummy") && !key.isEmpty
    }
}
