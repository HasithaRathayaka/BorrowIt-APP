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
        
        // Initialize default user location to Colombo 07 Center (6.9064, 79.8708)
        self.userCoordinate = AppConfig.cedarGroveCenter
        
        let status = locationManager.authorizationStatus
        self.isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        if isAuthorized {
            locationManager.startUpdatingLocation()
        }
    }
    
    public func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
        if isAuthorized {
            locationManager.startUpdatingLocation()
        }
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
        let lat = latest.coordinate.latitude
        let lon = latest.coordinate.longitude
        // If simulator defaults to US/Cupertino coordinates (lat > 20 or lon < 0), preserve Colombo 07 center
        if lat > 20.0 || lon < 0.0 {
            self.userCoordinate = AppConfig.cedarGroveCenter
        } else {
            self.userCoordinate = Coordinate(latitude: lat, longitude: lon)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == "borrowit_handoff_geofence" {
            self.isWithin50mOfActiveHandoff = true
            self.onGeofenceArrival?()
        }
    }
}
