import Combine
import CoreLocation
import CoreMotion
import Foundation
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Properties

    private var manager = CLLocationManager()
    private var motionManager = CMMotionActivityManager()

    // CRITICAL FIX: Add motion detection state management
    private var isMotionDetectionActive = false

    // Published properties
    @Published var locations: [CLLocation] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var debugLogs: [String] = []
    @Published var isTracking = false
    @Published var isMockMode = false
    @Published var mockTripIndex = 0

    // Component managers
    private let diagnosticManager = DiagnosticManager()
    private let tripDetection = TripDetection()
    private let testCaseManager = TestCaseManager()

    // MEMORY LEAK FIX: Add array size limits
    private let maxLocationHistory = 1000 // Keep last 1000 locations to prevent unbounded growth

    // THREADING OPTIMIZATION: Cache authorization status to reduce system calls
    private var lastAuthorizationCheck: Date = .init()
    private let authorizationCheckInterval: TimeInterval = 30.0 // Check every 30 seconds max

    #if DEBUG
        private var mockLocationTimer: Timer?
        private var mockLocationIndex: Int = 0
    #endif

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
        setupMotionManager()
        setupDependencies()
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    // MARK: - Setup Methods

    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = DistanceConverter.getLocationDistanceFilter() // ~0.01 miles
        // CRITICAL FIX: Only enable background updates after proper authorization
        // manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    private func setupMotionManager() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            addLog("⚠️ Motion activity not available")
            return
        }
    }

    private func setupDependencies() {
        // Set up TestCaseManager dependencies
        testCaseManager.setDependencies(diagnosticManager: diagnosticManager, locationManager: self)

        // Initialize DiagnosticManager with current authorization status
        diagnosticManager.updateAuthorizationStatus(authorizationStatus)

        addLog("📍 Dependencies configured for test case management")
    }

    // MARK: - Public Methods

    func requestLocationPermission() {
        addLog("📍 Requesting location permission")
        // CRITICAL FIX: Move to background thread to avoid UI blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.manager.requestAlwaysAuthorization()
        }
    }

    func startTracking() {
        // Idempotent: if already tracking, do nothing
        if isTracking {
            addLog("ℹ️ Tracking already active")
            return
        }

        // Immediately reflect tracking state (user intent)
        isTracking = true

        // Handle mock mode separately
        if isMockMode {
            tripDetection.startTripDetection()

            if diagnosticManager.diagnosticMode {
                diagnosticManager.startDiagnosticMode()
            }

            addLog("🧪 Mock tracking started")
            return
        }

        // If permission not granted yet, request it but keep tracking enabled
        if !(authorizationStatus == .authorizedAlways || authorizationStatus ==
            .authorizedWhenInUse
        ) {
            locationError = "Location permission not granted"
            addLog("⚠️ Tracking requested, permission not granted — requesting permission")
            requestLocationPermission()
            return
        }

        // Authorized path
        if authorizationStatus == .authorizedAlways {
            addLog("📍 Always authorization detected, skipping background updates for safety")
        } else {
            addLog("📍 Foreground-only location tracking (When In Use)")
        }

        manager.startUpdatingLocation()
        tripDetection.startTripDetection()

        if diagnosticManager.diagnosticMode {
            diagnosticManager.startDiagnosticMode()
        }

        addLog("📍 Location tracking started")
    }

    func stopTracking() {
        isTracking = false

        // CRITICAL FIX: Handle mock mode separately
        if isMockMode {
            tripDetection.stopTripDetection()

            if diagnosticManager.diagnosticMode {
                diagnosticManager.stopDiagnosticMode()
            }

            addLog("🧪 Mock tracking stopped")
            return
        }

        manager.stopUpdatingLocation()
        tripDetection.stopTripDetection()

        // CRITICAL FIX: Stop any active trip when location tracking stops
        if tripDetection.isTripActive {
            tripDetection.stopTrip()
        }

        if diagnosticManager.diagnosticMode {
            diagnosticManager.stopDiagnosticMode()
        }

        addLog("📍 Location tracking stopped")
    }

    func toggleMockMode() {
        isMockMode.toggle()

        if isMockMode {
            startMockLocationUpdates()
        } else {
            stopMockLocationUpdates()
        }

        addLog("🧪 Mock mode \(isMockMode ? "enabled" : "disabled")")
    }

    func startDiagnosticMode() {
        diagnosticManager.startDiagnosticMode()
        addLog("🔍 Diagnostic mode started")
    }

    func stopDiagnosticMode() {
        diagnosticManager.stopDiagnosticMode()
        addLog("🔍 Diagnostic mode stopped")
    }

    // MARK: - Test Case Management

    func startTestCase(name: String, notes: String = "") {
        testCaseManager.startTestCase(name: name, notes: notes)
    }

    func stopTestCase() {
        testCaseManager.stopTestCase()
    }

    func addTestCaseLog(_ message: String) {
        testCaseManager.addTestCaseLog(message)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let startTime = Date()

        // Add to location history
        self.locations.append(location)
        manageArraySize(&self.locations, maxSize: maxLocationHistory)

        // Process location for trip detection
        tripDetection.processLocation(location)

        // Add to test case if recording
        testCaseManager.addTestCaseLocation(location)

        // Diagnostic monitoring
        if diagnosticManager.diagnosticMode {
            diagnosticManager.addGPSQualitySnapshot(location)
            let processingTime = Date().timeIntervalSince(startTime)
            diagnosticManager.addLocationProcessingTime(processingTime)
        }

        addLog(
            "📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)"
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        addLog("❌ Location error: \(error.localizedDescription)")

        // Add to test case if recording
        testCaseManager.addTestCaseLog("Location error: \(error.localizedDescription)")
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        authorizationStatus = status
        updateAuthorizationCheckTime()

        // Update DiagnosticManager with new authorization status
        diagnosticManager.updateAuthorizationStatus(status)

        addLog("📍 Authorization status changed: \(status.rawValue)")

        switch status {
        case .authorizedAlways:
            locationError = nil
        // Background updates will be configured in startTracking() when needed
        case .authorizedWhenInUse:
            locationError = nil
        // Background updates will be configured in startTracking() when needed
        case .denied, .restricted:
            locationError = "Location access denied"
            stopTracking()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Private Methods

    private func manageArraySize<T>(_ array: inout [T], maxSize: Int) {
        if array.count > maxSize {
            let excess = array.count - maxSize
            array.removeFirst(excess)
        }
    }

    private func shouldCheckAuthorizationStatus() -> Bool {
        let timeSinceLastCheck = Date().timeIntervalSince(lastAuthorizationCheck)
        return timeSinceLastCheck >= authorizationCheckInterval
    }

    private func updateAuthorizationCheckTime() {
        lastAuthorizationCheck = Date()
    }

    private func addLog(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        debugLogs.append("[\(timestamp)] \(message)")

        // Keep logs manageable
        if debugLogs.count > 100 {
            debugLogs.removeFirst(50)
        }

        print("📍 [LocationManager] \(message)")
    }

    // MARK: - Mock Location Methods

    #if DEBUG
        private func startMockLocationUpdates() {
            mockLocationTimer = Timer
                .scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                    self?.addMockLocation()
                }
        }

        private func stopMockLocationUpdates() {
            mockLocationTimer?.invalidate()
            mockLocationTimer = nil
        }

        func addMockLocation() {
            // Simple mock location generation
            let mockLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.7749 + Double.random(in: -0.01 ... 0.01),
                    longitude: -122.4194 + Double.random(in: -0.01 ... 0.01)
                ),
                altitude: 0,
                horizontalAccuracy: 5.0,
                verticalAccuracy: 10.0,
                timestamp: Date()
            )

            // Simulate location update
            locationManager(manager, didUpdateLocations: [mockLocation])
        }

        func nextMockTrip() {
            mockTripIndex += 1
            addLog("🧪 Next mock trip: \(mockTripIndex)")
        }

        func getMockTripCount() -> Int {
            return 5 // Mock value
        }

        func getCurrentMockTripInfo() -> String {
            return "Mock Trip \(mockTripIndex + 1)"
        }
    #endif

    // MARK: - Public Access to Components

    var diagnosticMode: Bool {
        get { diagnosticManager.diagnosticMode }
        set {
            if newValue {
                diagnosticManager.startDiagnosticMode()
            } else {
                diagnosticManager.stopDiagnosticMode()
            }
        }
    }

    var diagnosticIssues: [DiagnosticIssue] {
        diagnosticManager.diagnosticIssues
    }

    var isTripActive: Bool {
        tripDetection.isTripActive
    }

    var tripStartTime: Date? {
        tripDetection.tripStartTime
    }

    var tripEndTime: Date? {
        tripDetection.tripEndTime
    }

    var currentTripDistance: Double {
        let distance = tripDetection.currentTripDistance
        return distance.isFinite ? distance : 0.0
    }

    var totalAccumulatedDistance: Double {
        let distance = tripDetection.getTotalAccumulatedDistance()
        return distance.isFinite ? distance : 0.0
    }

    // MARK: - Trip Management

    func startTrip() {
        tripDetection.startTrip()
    }

    func stopTrip() {
        tripDetection.stopTrip()
    }

    var currentTestCase: String {
        testCaseManager.currentTestCase
    }

    var testCaseNotes: String {
        testCaseManager.testCaseNotes
    }

    var savedTestCases: [TestCase] {
        testCaseManager.savedTestCases
    }

    var isRecordingTestCase: Bool {
        testCaseManager.isRecordingTestCase
    }

    // MARK: - Test Case Management Methods

    func clearAllTestCases() {
        testCaseManager.clearAllTestCases()
    }

    func getTestCaseSummary() -> String {
        testCaseManager.getTestCaseSummary()
    }

    func exportAllTestCases() {
        testCaseManager.exportAllTestCasesWithDiagnostics(diagnosticIssues)
    }
}
