import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - CoreLocation Geofencing & Distance Tracking
public class LocationGeofenceService: NSObject, ObservableObject, GeofenceServiceProtocol, CLLocationManagerDelegate {
    public static let shared = LocationGeofenceService()
    
    @Published public var userCoordinate: Coordinate?
    @Published public var isAuthorized: Bool = false
    @Published public var isWithin50mOfActiveHandoff: Bool = false
    
    private let locationManager = CLLocationManager()
    private var geofenceRegion: CLCircularRegion?
    private var onGeofenceArrival: (() -> Void)?
    
    public var currentCoordinate: Coordinate? {
        userCoordinate
    }
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Initialize default user location to Cedar Grove Center (37.7749, -122.4194)
        self.userCoordinate = AppConfig.cedarGroveCenter
        
        let status = locationManager.authorizationStatus
        self.isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    public func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Distance Calculation in Meters
    public func checkDistanceTo(coordinate: Coordinate) -> Double {
        let userLoc = CLLocation(
            latitude: userCoordinate?.latitude ?? AppConfig.cedarGroveCenter.latitude,
            longitude: userCoordinate?.longitude ?? AppConfig.cedarGroveCenter.longitude
        )
        let targetLoc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return userLoc.distance(from: targetLoc)
    }
    
    // MARK: - 50m Geofence Monitoring
    public func startMonitoringGeofence(target: Coordinate, radiusMeters: Double = 50.0, onArrival: @escaping () -> Void) {
        self.onGeofenceArrival = onArrival
        
        let center = CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
        let region = CLCircularRegion(
            center: center,
            radius: radiusMeters,
            identifier: "borrowit_handoff_geofence"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        self.geofenceRegion = region
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager.startMonitoring(for: region)
        }
    }
    
    public func stopMonitoring() {
        if let region = geofenceRegion {
            locationManager.stopMonitoring(for: region)
        }
        geofenceRegion = nil
        onGeofenceArrival = nil
        isWithin50mOfActiveHandoff = false
    }
    
    // MARK: - Simulation Trigger for Demos & Xcode Simulator
    public func simulateGeofenceArrival() {
        print("[LocationGeofenceService] Triggered 50m Geofence entry simulation.")
        self.isWithin50mOfActiveHandoff = true
        self.onGeofenceArrival?()
    }
    
    // MARK: - CLLocationManagerDelegate
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        self.isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        if isAuthorized {
            locationManager.startUpdatingLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        self.userCoordinate = Coordinate(latitude: latest.coordinate.latitude, longitude: latest.coordinate.longitude)
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "borrowit_handoff_geofence" {
            self.isWithin50mOfActiveHandoff = true
            self.onGeofenceArrival?()
        }
    }
}
