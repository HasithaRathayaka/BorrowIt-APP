import Foundation

public struct AppConfig {
    // Supabase backend configuration
    public static let supabaseURL = URL(string: "https://xvsoruwrbtpzctvitujv.supabase.co")!
    public static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh2c29ydXdyYnRwemN0dml0dWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxNzk4NjYsImV4cCI6MjEwODc1NTg2Nn0.880XRFVVWS_YvNKn6BK_KopgZou3fn3YfVpfrKoyWkY"
    
    // Shared App Group for WidgetKit & AppIntents
    public static let appGroupIdentifier = "group.com.borrowit.shared"
    
    // Colombo 07 (Cinnamon Gardens / Reid Ave) Neighborhood Default Center
    public static let colomboCenter = Coordinate(latitude: 6.9064, longitude: 79.8708)
    public static let cedarGroveCenter = colomboCenter // Alias for backward compatibility
    public static let defaultSearchRadiusMeters: Double = 500.0
    public static let geofenceArrivalRadiusMeters: Double = 50.0
    public static let qrTokenExpirationSeconds: TimeInterval = 300.0 // 5 minutes
    
    // Runtime Mode Check
    public static var isSupabaseConfigured: Bool {
        let key = supabaseAnonKey
        return !key.contains("dummy") && !key.isEmpty
    }
}
