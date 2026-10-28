import Foundation

public struct AppConfig {
    // Supabase backend configuration
    public static let supabaseURL = URL(string: "https://xvsoruwrbtpzctvitujv.supabase.co")!
    public static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh2c29ydXdyYnRwemN0dml0dWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxNzk4NjYsImV4cCI6MjEwODc1NTg2Nn0.880XRFVVWS_YvNKn6BK_KopgZou3fn3YfVpfrKoyWkY"
    
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
