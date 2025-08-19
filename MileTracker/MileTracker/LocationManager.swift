import Foundation
import CoreLocation
import CoreMotion
import Combine
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Properties
    
    private var manager = CLLocationManager()
    private var motionManager = CMMotionActivityManager()
    
    // CRITICAL FIX: Add motion detection state management
    private var isMotionDetectionActive = false
    
    @Published var locations: [CLLocation] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var debugLogs: [String] = []
    @Published var isTracking = false
    @Published var isMockMode = false
    @Published var mockTripIndex = 0
    @Published var isTripActive = false
    @Published var tripStartTime: Date?
    @Published var tripEndTime: Date?
    @Published var currentTripDistance: Double = 0.0
    
    // MARK: - Test Case Management Properties
    @Published var currentTestCase: String = "Default Test"
    @Published var testCaseNotes: String = ""
    @Published var savedTestCases: [TestCase] = []
    @Published var isRecordingTestCase = false
    
    // MARK: - Trip Detection Properties
    private var speedDetectionStartTime: Date?
    private var lastMovementTime: Date?
    private var speedThreshold: Double = 5.0 // mph
    private var speedDetectionDuration: TimeInterval = 15.0 // seconds
    private var autoStopDuration: TimeInterval = 120.0 // 2 minutes
    
    // MARK: - Timers
    private var tripDetectionTimer: Timer?
    private var autoStopTimer: Timer?
    
    #if DEBUG
    private var mockLocationTimer: Timer?
    private var mockLocationIndex: Int = 0
    #endif
    
    // MARK: - Test Case Structure
    struct TestCase: Identifiable, Codable {
        let id: UUID
        let name: String
        let notes: String
        let startTime: Date
        let endTime: Date
        let logs: [String]
        let locations: [LocationData]
        let tripData: TripData?
        let deviceInfo: DeviceInfo
        
        struct LocationData: Codable {
            let latitude: Double
            let longitude: Double
            let timestamp: Date
            let accuracy: Double
        }
        
        struct TripData: Codable {
            let isActive: Bool
            let startTime: Date?
            let endTime: Date?
            let distance: Double
            let duration: TimeInterval?
        }
        
        struct DeviceInfo: Codable {
            let deviceModel: String
            let iOSVersion: String
            let appVersion: String
        }
    }
    
    // MARK: - Test Case Management Methods
    
    // MARK: - Persistent Storage Keys
    private let testCasesStorageKey = "MileTracker_SavedTestCases"
    
    // MARK: - Persistent Storage Methods
    private func saveTestCasesToStorage() {
        do {
            let data = try JSONEncoder().encode(savedTestCases)
            UserDefaults.standard.set(data, forKey: testCasesStorageKey)
            addLog("💾 Test cases saved to persistent storage: \(savedTestCases.count) cases")
        } catch {
            addLog("❌ Failed to save test cases to storage: \(error.localizedDescription)")
        }
    }
    
    private func loadTestCasesFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: testCasesStorageKey) else {
            addLog("ℹ️ No saved test cases found in storage")
            return
        }
        
        do {
            let loadedTestCases = try JSONDecoder().decode([TestCase].self, from: data)
            savedTestCases = loadedTestCases
            addLog("📱 Loaded \(loadedTestCases.count) test cases from persistent storage")
        } catch {
            addLog("❌ Failed to load test cases from storage: \(error.localizedDescription)")
            // If loading fails, start with empty array
            savedTestCases = []
        }
    }
    
    func startTestCase(name: String, notes: String = "") {
        currentTestCase = name
        testCaseNotes = notes
        isRecordingTestCase = true
        
        // Clear previous logs for this test case
        debugLogs.removeAll()
        
        addLog("🧪 ===== TEST CASE STARTED =====")
        addLog("🧪 Test Case: \(name)")
        if !notes.isEmpty {
            addLog("🧪 Notes: \(notes)")
        }
        addLog("🧪 Start Time: \(formatTime(Date()))")
        addLog("🧪 Current locations: \(locations.count)")
        addLog("🧪 Current distance: \(String(format: "%.2f", calculateTotalDistance())) miles")
        addLog("🧪 ================================")
        
        #if DEBUG
        // Reset mock mode state for new test case
        if isMockMode {
            addLog("🔄 Resetting mock mode for new test case")
            addLog("📍 Mock location index before reset: \(mockLocationIndex)")
            mockLocationIndex = 0
            addLog("📍 Mock location index reset to 0")
            addLog("📍 Current mock trip: \(mockTripIndex + 1) of \(mockTrips.count)")
            addLog("📍 Mock trip has \(mockTrips[mockTripIndex].count) locations available")
        }
        #endif
        
        // Don't reset trip data - let it continue naturally
        // resetTripData() // Commented out to preserve trip state during test cases
    }
    
    func endTestCase() {
        guard isRecordingTestCase else { return }
        
        isRecordingTestCase = false
        
        addLog("🧪 ===== TEST CASE ENDED =====")
        addLog("🧪 Test Case: \(currentTestCase)")
        addLog("🧪 End Time: \(formatTime(Date()))")
        addLog("🧪 ================================")
        
        // Save the test case
        saveCurrentTestCase()
        
        // Reset for next test
        currentTestCase = "Default Test"
        testCaseNotes = ""
    }
    
    func saveCurrentTestCase() {
        // Capture the current state more accurately
        let actualStartTime = Date().addingTimeInterval(-TimeInterval(debugLogs.count * 2))
        let actualEndTime = Date()
        
        // Calculate actual distance from current locations
        let actualDistance = calculateDistance(locations: locations)
        
        let testCase = TestCase(
            id: UUID(),
            name: currentTestCase,
            notes: testCaseNotes,
            startTime: actualStartTime,
            endTime: actualEndTime,
            logs: debugLogs,
            locations: locations.map { location in
                TestCase.LocationData(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    timestamp: location.timestamp,
                    accuracy: location.horizontalAccuracy
                )
            },
            tripData: TestCase.TripData(
                isActive: isTripActive,
                startTime: tripStartTime,
                endTime: tripEndTime,
                distance: actualDistance, // Use calculated distance instead of currentTripDistance
                duration: tripStartTime != nil ? actualEndTime.timeIntervalSince(tripStartTime!) : nil
            ),
            deviceInfo: TestCase.DeviceInfo(
                deviceModel: UIDevice.current.model,
                iOSVersion: UIDevice.current.systemVersion,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            )
        )
        
        savedTestCases.append(testCase)
        addLog("💾 Test case '\(currentTestCase)' saved successfully")
        addLog("💾 Total test cases saved: \(savedTestCases.count)")
        addLog("💾 Captured \(locations.count) locations with \(String(format: "%.2f", actualDistance)) miles")
        
        // Automatically save to persistent storage
        saveTestCasesToStorage()
    }
    
    func exportTestCase(_ testCase: TestCase) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        var report = "=== MileTracker Test Case Report ===\n"
        report += "Test Case: \(testCase.name)\n"
        report += "Notes: \(testCase.notes)\n"
        report += "Start Time: \(dateFormatter.string(from: testCase.startTime))\n"
        report += "End Time: \(dateFormatter.string(from: testCase.endTime))\n"
        report += "Device: \(testCase.deviceInfo.deviceModel)\n"
        report += "iOS Version: \(testCase.deviceInfo.iOSVersion)\n"
        report += "App Version: \(testCase.deviceInfo.appVersion)\n\n"
        
        if let tripData = testCase.tripData {
            report += "=== Trip Data ===\n"
            report += "Trip Active: \(tripData.isActive)\n"
            if let startTime = tripData.startTime {
                report += "Trip Start: \(dateFormatter.string(from: startTime))\n"
            }
            if let endTime = tripData.endTime {
                report += "Trip End: \(dateFormatter.string(from: endTime))\n"
            }
            report += "Trip Distance: \(String(format: "%.2f", tripData.distance)) miles\n"
            if let duration = tripData.duration {
                report += "Trip Duration: \(formatDuration(duration))\n"
            }
            report += "\n"
        }
        
        report += "=== Location Data ===\n"
        report += "Total GPS Points: \(testCase.locations.count)\n\n"
        
        for (index, location) in testCase.locations.enumerated() {
            report += "Location \(index + 1):\n"
            report += "  Lat: \(String(format: "%.6f", location.latitude))\n"
            report += "  Lon: \(String(format: "%.6f", location.longitude))\n"
            report += "  Time: \(dateFormatter.string(from: location.timestamp))\n"
            report += "  Accuracy: \(String(format: "%.1fm", location.accuracy))\n\n"
        }
        
        report += "=== Debug Logs ===\n"
        for log in testCase.logs {
            report += "\(log)\n"
        }
        
        return report
    }
    
    func exportAllTestCases() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var report = "=== MileTracker All Test Cases Report ===\n"
        report += "Generated: \(dateFormatter.string(from: Date()))\n"
        report += "Total Test Cases: \(savedTestCases.count)\n\n"
        
        for (index, testCase) in savedTestCases.enumerated() {
            report += "--- Test Case \(index + 1) ---\n"
            report += "Name: \(testCase.name)\n"
            report += "Date: \(dateFormatter.string(from: testCase.startTime))\n"
            report += "Locations: \(testCase.locations.count)\n"
            
            // Calculate actual distance from saved location data
            let calculatedDistance = calculateDistanceFromLocationData(testCase.locations)
            report += "Calculated Distance: \(String(format: "%.2f", calculatedDistance)) miles\n"
            
            if let tripData = testCase.tripData {
                report += "Trip Distance: \(String(format: "%.2f", tripData.distance)) miles\n"
            }
            report += "\n"
        }
        
        return report
    }
    
    func clearAllTestCases() {
        savedTestCases.removeAll()
        UserDefaults.standard.removeObject(forKey: testCasesStorageKey)
        addLog("🗑️ All test cases cleared from memory and persistent storage")
    }
    
    func saveAllTestCasesToStorage() {
        saveTestCasesToStorage()
        addLog("💾 Manually saved all test cases to persistent storage")
    }
    
    func getTestCaseSummary() -> String {
        var summary = "📊 Test Case Summary\n"
        summary += "Total Saved: \(savedTestCases.count)\n\n"
        
        for (index, testCase) in savedTestCases.enumerated() {
            summary += "\(index + 1). \(testCase.name)\n"
            summary += "   📍 \(testCase.locations.count) GPS points\n"
            if let tripData = testCase.tripData {
                summary += "   🚗 \(String(format: "%.2f", tripData.distance)) miles\n"
            }
            summary += "\n"
        }
        
        return summary
    }
    
    func checkBackgroundLocationAvailability() -> Bool {
        return manager.allowsBackgroundLocationUpdates
    }

    #if DEBUG
    private let mockTrips: [[CLLocation]] = [
        // Trip 1: NYC to Queens (about 8.5 miles)
        [
            CLLocation(latitude: 40.7128, longitude: -74.0060), // NYC Financial District
            CLLocation(latitude: 40.730610, longitude: -73.935242), // Queens
            CLLocation(latitude: 40.758896, longitude: -73.985130), // Times Square
            CLLocation(latitude: 40.7505, longitude: -73.9934), // Penn Station
            CLLocation(latitude: 40.7484, longitude: -73.9857), // Empire State Building
            CLLocation(latitude: 40.7589, longitude: -73.9851), // Times Square
            CLLocation(latitude: 40.7505, longitude: -73.9934), // Penn Station
            CLLocation(latitude: 40.730610, longitude: -73.935242) // Queens
        ],
        
        // Trip 2: Boston to Cambridge (about 3.2 miles)
        [
            CLLocation(latitude: 42.3601, longitude: -71.0589), // Boston Common
            CLLocation(latitude: 42.3736, longitude: -71.1097), // Harvard Square
            CLLocation(latitude: 42.3656, longitude: -71.1040), // MIT
            CLLocation(latitude: 42.3601, longitude: -71.0589) // Back to Boston
        ],
        
        // Trip 3: San Francisco Loop (about 5.8 miles)
        [
            CLLocation(latitude: 37.7749, longitude: -122.4194), // Fisherman's Wharf
            CLLocation(latitude: 37.8099, longitude: -122.4104), // Golden Gate Bridge
            CLLocation(latitude: 37.7694, longitude: -122.4862), // Golden Gate Park
            CLLocation(latitude: 37.7749, longitude: -122.4194) // Back to Wharf
        ],
        
        // Trip 4: Chicago Downtown (about 4.1 miles)
        [
            CLLocation(latitude: 41.8781, longitude: -87.6298), // Millennium Park
            CLLocation(latitude: 41.9000, longitude: -87.6500), // Wrigley Field
            CLLocation(latitude: 41.8781, longitude: -87.6298) // Back to Park
        ]
    ]
    
    func toggleMockMode() {
        isMockMode.toggle()
        if isMockMode {
            addLog("🔄 Mock mode enabled - using simulated GPS data")
            // Reset to first trip
            mockTripIndex = 0
            // mockLocationIndex = 0 // This line was removed from the new_code, so it's removed here.
        } else {
            addLog("📍 Mock mode disabled - using real GPS data")
            // Clear any mock locations
            if isTracking {
                locations.removeAll()
            }
            // Stop any active mock timer
            stopMockLocationUpdates()
        }
    }
    
    func nextMockTrip() {
        mockTripIndex = (mockTripIndex + 1) % mockTrips.count
        // mockLocationIndex = 0 // This line was removed from the new_code, so it's removed here.
        addLog("🛣️ Switched to mock trip \(mockTripIndex + 1) of \(mockTrips.count)")
    }
    
    func simulateLocationUpdates() {
        guard isMockMode else { 
            addLog("❌ Cannot simulate: Mock mode not enabled")
            return 
        }
        
        // Stop any existing timer
        stopMockLocationUpdates()
        
        addLog("📍 Starting mock location simulation for Trip \(mockTripIndex + 1)")
        addLog("📍 Trip has \(mockTrips[mockTripIndex].count) locations to simulate")
        addLog("📍 Current mockLocationIndex: \(mockLocationIndex)")
        addLog("📍 Will add locations from index \(mockLocationIndex) to \(mockTrips[mockTripIndex].count - 1)")
        
        // CRITICAL FIX: Simulate automotive activity in Mock Mode
        // This allows testing the speed detection logic without real motion
        addLog("🚗 Simulating automotive activity for Mock Mode testing")
        
        // Ensure we're tracking before simulating automotive activity
        if !isTracking {
            addLog("📍 Starting location tracking for Mock Mode")
            startLocationUpdates()
        }
        
        // Simulate automotive activity after a short delay to ensure tracking is active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.handleAutomotiveActivity()
        }
        
        // Simulate GPS updates every 2 seconds on main run loop
        mockLocationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Check if we should still be simulating
            guard self.isMockMode else {
                self.addLog("❌ Stopping simulation: Mock mode disabled")
                timer.invalidate()
                return
            }
            
            if self.mockLocationIndex < self.mockTrips[self.mockTripIndex].count {
                let mockLocation = self.mockTrips[self.mockTripIndex][self.mockLocationIndex]
                let latString = String(format: "%.4f", mockLocation.coordinate.latitude)
                let lonString = String(format: "%.4f", mockLocation.coordinate.longitude)
                
                self.addLog("📍 Mock GPS \(self.mockLocationIndex + 1): \(latString), \(lonString)")
                
                // Add location on main thread
                DispatchQueue.main.async {
                    self.locations.append(mockLocation)
                    self.addLog("✅ Added mock location \(self.mockLocationIndex + 1) - Total locations: \(self.locations.count)")
                }
                
                self.mockLocationIndex += 1
                self.addLog("📍 Incremented mockLocationIndex to: \(self.mockLocationIndex)")
            } else {
                timer.invalidate()
                self.addLog("✅ Mock trip \(self.mockTripIndex + 1) completed - \(self.mockTrips[self.mockTripIndex].count) locations added")
                self.addLog("📍 Final mockLocationIndex: \(self.mockLocationIndex)")
            }
        }
        
        // Ensure timer is added to main run loop
        RunLoop.main.add(mockLocationTimer!, forMode: .common)
        
        addLog("⏰ Mock location timer started - will add \(mockTrips[mockTripIndex].count) locations every 2 seconds")
    }
    
    private func stopMockLocationUpdates() {
        mockLocationTimer?.invalidate()
        mockLocationTimer = nil
        // mockLocationIndex = 0 // This line was removed from the new_code, so it's removed here.
    }
    #endif
    
    // MARK: - Trip Detection Methods
    
    private func setupMotionDetection() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            addLog("❌ Core Motion not available on this device")
            return
        }
        
        // CRITICAL FIX: Prevent multiple motion detection setups
        if isMotionDetectionActive {
            addLog("⚠️ Motion detection already active - skipping setup")
            return
        }
        
        addLog("🔄 Setting up Core Motion activity detection")
        isMotionDetectionActive = true
        
        // CRITICAL FIX: Add throttling to prevent system overload
        var lastMotionLogTime: Date = Date.distantPast
        let motionThrottleInterval: TimeInterval = 1.0 // Only log motion changes every 1 second
        
        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            
            let now = Date()
            let timeSinceLastLog = now.timeIntervalSince(lastMotionLogTime)
            
            // Throttle motion logging to prevent system overload
            if timeSinceLastLog >= motionThrottleInterval {
                let activityType = self.getActivityDescription(activity)
                self.addLog("🔄 Motion detected: \(activityType) (automotive: \(activity.automotive))")
                lastMotionLogTime = now
                
                DispatchQueue.main.async {
                    if activity.automotive {
                        self.addLog("🚗 Automotive activity detected")
                        self.handleAutomotiveActivity()
                    } else if activity.walking || activity.running || activity.cycling {
                        self.addLog("🚶 Non-automotive activity: \(activityType)")
                        self.handleNonAutomotiveActivity()
                    } else {
                        // Don't log every "Stationary" or "Unknown" activity to reduce noise
                        if activityType != "Stationary" && activityType != "Unknown" {
                            self.addLog("ℹ️ Other activity: \(activityType)")
                        }
                    }
                }
            }
        }
        
        addLog("✅ Core Motion activity detection started")
    }
    
    private func getActivityDescription(_ activity: CMMotionActivity) -> String {
        if activity.automotive { return "Automotive" }
        if activity.walking { return "Walking" }
        if activity.running { return "Running" }
        if activity.cycling { return "Cycling" }
        if activity.stationary { return "Stationary" }
        return "Unknown"
    }
    
    private var lastAutomotiveActivityTime: Date? = nil
    
    private func handleAutomotiveActivity() {
        addLog("🚗 handleAutomotiveActivity() called")
        
        // CRITICAL FIX: Don't start speed detection if trip is already active
        if isTripActive {
            addLog("🚗 Automotive activity detected but trip already active - continuing existing trip")
            return
        }
        
        // CRITICAL FIX: Add throttling to prevent infinite loops
        // Only process automotive activity if we haven't processed it recently
        let now = Date()
        if let lastAutomotiveTime = lastAutomotiveActivityTime {
            let timeSinceLastActivity = now.timeIntervalSince(lastAutomotiveTime)
            if timeSinceLastActivity < 2.0 { // Minimum 2 seconds between activities
                addLog("🚗 Throttling automotive activity (last: \(String(format: "%.1f", timeSinceLastActivity))s ago)")
                return
            }
        }
        lastAutomotiveActivityTime = now
        
        // Only start speed detection if not already active
        if speedDetectionStartTime == nil {
            speedDetectionStartTime = now
            addLog("🚗 Starting speed detection timer")
            
            // CRITICAL FIX: Start location tracking immediately to collect GPS data
            if !isTracking {
                addLog("📍 Starting location tracking for speed detection")
                startLocationUpdates()
            } else {
                addLog("📍 Location tracking already active")
            }
            
            // Start monitoring speed for trip start
            startSpeedDetectionTimer()
        } else {
            addLog("🚗 Automotive activity detected (speed detection already active)")
        }
    }
    
    private func handleNonAutomotiveActivity() {
        // Stop speed detection for non-automotive activities
        if speedDetectionStartTime != nil {
            speedDetectionStartTime = nil
            lastAutomotiveActivityTime = nil // Reset automotive activity timer
            stopSpeedDetectionTimer()
            addLog("🚶 Stopping speed detection - non-automotive activity")
            
            // CRITICAL FIX: Stop location tracking if no trip is active
            // This conserves battery by only tracking when needed
            if !isTripActive && isTracking {
                addLog("📍 Stopping location tracking - no automotive activity")
                stopLocationUpdates()
            }
        }
    }
    
    private func startSpeedDetectionTimer() {
        stopSpeedDetectionTimer()
        
        // CRITICAL FIX: Don't start speed detection if trip is already active
        if isTripActive {
            addLog("⚠️ Cannot start speed detection - trip already active")
            return
        }
        
        addLog("⏰ Starting speed detection timer - checking every 1 second")
        addLog("📊 Need \(speedThreshold) mph for \(Int(speedDetectionDuration)) seconds to start trip")
        
        // CRITICAL FIX: Use weak self to prevent retain cycles
        tripDetectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Check if speed detection is still active
            guard self.speedDetectionStartTime != nil else {
                self.addLog("⏰ Speed detection cancelled - stopping timer")
                timer.invalidate()
                return
            }
            
            // CRITICAL FIX: Don't check speed if trip is already active
            if self.isTripActive {
                self.addLog("⏰ Speed detection cancelled - trip already active")
                timer.invalidate()
                return
            }
            
            self.checkSpeedForTripStart()
        }
        
        addLog("⏰ Speed detection timer started")
    }
    
    private func stopSpeedDetectionTimer() {
        tripDetectionTimer?.invalidate()
        tripDetectionTimer = nil
    }
    
    private func checkSpeedForTripStart() {
        guard let startTime = speedDetectionStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, speedDetectionDuration - elapsed)
        
        // Log progress every few seconds
        if Int(elapsed) % 5 == 0 && elapsed > 0 {
            addLog("⏰ Speed detection progress: \(Int(elapsed))s elapsed, \(Int(remaining))s remaining")
        }
        
        if elapsed >= speedDetectionDuration {
            addLog("⏰ Speed detection timer completed - checking speed data")
            
            // Check if we have recent locations with sufficient speed
            // Look at the last few locations to get a better speed reading
            let recentLocations = Array(locations.suffix(5)) // Last 5 locations
            addLog("📍 Checking \(recentLocations.count) recent locations for speed calculation")
            
            guard recentLocations.count >= 2 else { 
                addLog("⚠️ Not enough locations for speed check (need 2+, have \(recentLocations.count))")
                addLog("💡 This usually means location tracking didn't start or GPS data isn't being received")
                speedDetectionStartTime = nil
                stopSpeedDetectionTimer()
                return 
            }
            
            // Calculate average speed from recent locations
            var totalSpeed: Double = 0
            var validSpeedCount = 0
            
            for i in 1..<recentLocations.count {
                let location = recentLocations[i]
                let previousLocation = recentLocations[i-1]
                
                // Calculate speed between consecutive points
                let distance = location.distance(from: previousLocation)
                let timeInterval = location.timestamp.timeIntervalSince(previousLocation.timestamp)
                
                if timeInterval > 0 {
                    let speed = distance / timeInterval // m/s
                    let speedMph = speed * 2.23694
                    
                    if speedMph > 0 { // Only count valid speeds
                        totalSpeed += speedMph
                        validSpeedCount += 1
                        addLog("📊 Segment \(i): \(String(format: "%.1f", speedMph)) mph")
                    }
                }
            }
            
            if validSpeedCount > 0 {
                let averageSpeed = totalSpeed / Double(validSpeedCount)
                addLog("📊 Average speed over \(validSpeedCount) segments: \(String(format: "%.1f", averageSpeed)) mph")
                
                if averageSpeed >= speedThreshold {
                    addLog("✅ Speed threshold met! Starting trip...")
                    startTrip()
                } else {
                    addLog("⚠️ Speed threshold not met: \(String(format: "%.1f", averageSpeed)) mph (need \(speedThreshold) mph)")
                }
            } else {
                addLog("⚠️ No valid speed readings available - all segments had 0 speed")
            }
            
            // Reset detection regardless of result
            speedDetectionStartTime = nil
            stopSpeedDetectionTimer()
        }
    }
    
    private func startTrip() {
        guard !isTripActive else { 
            addLog("⚠️ Trip start requested but trip already active - ignoring")
            return 
        }
        
        isTripActive = true
        tripStartTime = Date()
        currentTripDistance = 0.0
        
        addLog("🚀 Trip started automatically at \(formatTime(tripStartTime!))")
        addLog("📍 Starting location tracking for trip")
        
        // Start location updates if not already running
        if !isTracking {
            startLocationUpdates()
        }
        
        // Start auto-stop timer
        startAutoStopTimer()
        
        // CRITICAL FIX: Clear speed detection state to prevent new detection cycles
        speedDetectionStartTime = nil
        stopSpeedDetectionTimer()
        addLog("✅ Speed detection cleared - trip now active")
    }
    
    private func stopTrip() {
        guard isTripActive else { return }
        
        isTripActive = false
        tripEndTime = Date()
        
        let tripDuration = tripEndTime!.timeIntervalSince(tripStartTime!)
        let durationString = formatDuration(tripDuration)
        
        addLog("🛑 Trip ended automatically at \(formatTime(tripEndTime!))")
        addLog("⏱️ Trip duration: \(durationString)")
        addLog("📏 Trip distance: \(String(format: "%.2f", currentTripDistance)) miles")
        
        // Stop location updates
        stopLocationUpdates()
        
        // Stop auto-stop timer
        stopAutoStopTimer()
        
        // Reset trip data
        tripStartTime = nil
        tripEndTime = nil
        currentTripDistance = 0.0
    }
    
    private func startAutoStopTimer() {
        stopAutoStopTimer()
        
        autoStopTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForAutoStop()
        }
        
        addLog("⏰ Auto-stop timer started")
    }
    
    private func stopAutoStopTimer() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
    }
    
    private func checkForAutoStop() {
        guard let lastLocation = locations.last else { return }
        
        let currentTime = Date()
        let timeSinceLastMovement = currentTime.timeIntervalSince(lastLocation.timestamp)
        
        if timeSinceLastMovement >= autoStopDuration {
            addLog("⏰ Auto-stop triggered: No movement for \(Int(autoStopDuration)) seconds")
            stopTrip()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Public Trip Control Methods
    
    func startTripManually() {
        addLog("👆 Manual trip start requested")
        startTrip()
    }
    
    func stopTripManually() {
        addLog("👆 Manual trip stop requested")
        stopTrip()
    }
    
    func resetTripData() {
        addLog("🔄 Resetting trip data")
        isTripActive = false
        tripStartTime = nil
        tripEndTime = nil
        currentTripDistance = 0.0
        locations.removeAll()
        stopSpeedDetectionTimer()
        stopAutoStopTimer()
    }
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(message)"
        
        // Prevent duplicate consecutive log entries
        if let lastLog = debugLogs.last, lastLog == logEntry {
            return // Skip duplicate
        }
        
        DispatchQueue.main.async {
            self.debugLogs.append(logEntry)
            
            // Keep only last 50 logs to prevent memory issues and UI corruption
            if self.debugLogs.count > 50 {
                self.debugLogs.removeFirst(self.debugLogs.count - 50)
            }
        }
        
        // Also print to console for debugging
        print("LocationManager: \(message)")
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = true
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = 10 // Update every 10 meters
        // Note: allowsBackgroundLocationUpdates will be set after authorization
        
        // Don't check authorization status here - wait for delegate callback
        // This prevents UI unresponsiveness
        
        // Setup Core Motion for trip detection
        setupMotionDetection()
        
        // Load previously saved test cases from persistent storage
        loadTestCasesFromStorage()
    }
    
    func requestLocationPermission() {
        // Check if location services are enabled
        if CLLocationManager.locationServicesEnabled() {
            // Check current status to determine what to request
            let currentStatus = authorizationStatus
            print("LocationManager: Current status when requesting permission: \(currentStatus.rawValue)")
            
            // Use raw values to avoid enum comparison issues
            if currentStatus.rawValue == 0 { // .notDetermined
                print("LocationManager: Requesting Always authorization")
                manager.requestAlwaysAuthorization()
            } else if currentStatus.rawValue == 3 { // .authorizedWhenInUse
                print("LocationManager: User has When In Use, requesting Always")
                // User already has "When In Use" permission, request "Always"
                manager.requestAlwaysAuthorization()
            } else if currentStatus.rawValue == 4 { // .authorizedAlways
                print("LocationManager: Already have Always authorization")
                // Already have full permission, update status and start tracking
                DispatchQueue.main.async {
                    self.authorizationStatus = currentStatus
                    self.startLocationUpdates()
                }
            } else if currentStatus.rawValue == 2 || currentStatus.rawValue == 1 { // .denied || .restricted
                print("LocationManager: Authorization denied or restricted")
                locationError = "Location access denied. Please enable in Settings."
            } else {
                print("LocationManager: Unknown authorization status: \(currentStatus.rawValue)")
            }
        } else {
            print("LocationManager: Location services disabled")
            locationError = "Location services are disabled"
        }
    }
    
    func startLocationUpdates() {
        let logMessage = "Starting location updates"
        print("LocationManager: \(logMessage)")
        addLog(logMessage)

        #if DEBUG
        if isMockMode {
            addLog("🚀 Starting mock location tracking - Trip \(mockTripIndex + 1)")
            addLog("🔍 Mock mode details: isMockMode=\(isMockMode), isTracking=\(isTracking)")
            addLog("📍 Current locations before mock start: \(locations.count)")
            
            // Set tracking state first
            DispatchQueue.main.async {
                self.isTracking = true
                self.addLog("✅ Mock tracking state set to active")
                
                // Start simulation after state is set
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.addLog("🔄 Starting mock location simulation...")
                    self.simulateLocationUpdates()
                }
            }
            return
        }
        #endif
        
        // Only clear locations for real GPS tracking, not mock mode
        DispatchQueue.main.async {
            self.locations.removeAll()
            self.locationError = nil
        }
        
        // Check if we have permission before starting
        let currentStatus = authorizationStatus
        addLog("Current authorization status: \(currentStatus.rawValue)")

        if currentStatus.rawValue == 3 || currentStatus.rawValue == 4 { // .authorizedWhenInUse || .authorizedAlways
            addLog("Permission granted, starting location updates")
            manager.startUpdatingLocation()
            DispatchQueue.main.async {
                self.isTracking = true
            }
        } else {
            let errorMessage = "Cannot start location updates - no permission. Status: \(currentStatus.rawValue)"
            addLog(errorMessage)
            locationError = errorMessage
        }
    }
    
    func stopLocationUpdates() {
        let logMessage = "Stopping location updates"
        print("LocationManager: \(logMessage)")
        addLog(logMessage)
        
        manager.stopUpdatingLocation()
        
        DispatchQueue.main.async {
            self.isTracking = false
        }
        
        #if DEBUG
        stopMockLocationUpdates()
        #endif
        
        // Note: Don't stop trip detection here - let it continue monitoring
        addLog("Location updates stopped but trip detection remains active")
    }
    
    func forceStopLocationUpdates() {
        addLog("🛑 Force stopping all location and trip detection")
        
        // Stop location updates
        manager.stopUpdatingLocation()
        isTracking = false
        
        // Stop trip detection
        stopSpeedDetectionTimer()
        stopAutoStopTimer()
        
        // Stop mock mode if active
        #if DEBUG
        stopMockLocationUpdates()
        #endif
        
        addLog("✅ All tracking and detection stopped")
    }
    
    func isLocationUpdatesActive() -> Bool {
        return isTracking
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func getCurrentAuthorizationStatus() -> CLAuthorizationStatus {
        // Use the stored property instead of calling manager.authorizationStatus directly
        print("LocationManager: Current authorization status: \(authorizationStatus.rawValue)")
        return authorizationStatus
    }
    
    func clearDebugLogs() {
        DispatchQueue.main.async {
            self.debugLogs.removeAll()
        }
    }
    
    func exportDebugReport() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        var report = "=== MileTracker Debug Report ===\n"
        report = report + "Generated: \(dateFormatter.string(from: Date()))\n"
        report = report + "Device: \(UIDevice.current.model)\n"
        report = report + "iOS Version: \(UIDevice.current.systemVersion)\n\n"
        
        report = report + "=== Current Status ===\n"
        report = report + "Authorization Status: \(authorizationStatus.rawValue)\n"
        report = report + "Location Services Enabled: \(CLLocationManager.locationServicesEnabled())\n"
        report = report + "Total Locations Tracked: \(locations.count)\n"
        report = report + "Total Distance: \(String(format: "%.2f", self.calculateTotalDistance())) miles\n\n"
        
        if let error = locationError {
            report = report + "=== Errors ===\n"
            report = report + "\(error)\n\n"
        }
        
        report = report + "=== Debug Logs ===\n"
        for log in debugLogs {
            report = report + "\(log)\n"
        }
        
        report = report + "\n=== Location Data ===\n"
        if locations.isEmpty {
            report = report + "No locations tracked yet.\n"
        } else {
            for (index, location) in locations.enumerated() {
                report = report + "Location \(index + 1):\n"
                report = report + "  Lat: \(String(format: "%.6f", location.coordinate.latitude))\n"
                report = report + "  Lon: \(String(format: "%.6f", location.coordinate.longitude))\n"
                report = report + "  Time: \(dateFormatter.string(from: location.timestamp))\n"
                report = report + "  Accuracy: \(String(format: "%.1f", location.horizontalAccuracy))m\n"
                report = report + "\n"
            }
        }
        
        // Share the report
        let activityVC = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Distance Calculation
    
    func resetTrackingState() {
        addLog("🔄 Resetting tracking state")
        
        // CRITICAL FIX: Don't reset if speed detection is active
        if speedDetectionStartTime != nil {
            addLog("⚠️ Cannot reset tracking state - speed detection active")
            return
        }
        
        // Stop all timers and tracking
        stopLocationUpdates()
        stopSpeedDetectionTimer()
        stopAutoStopTimer()
        
        // Reset trip state
        isTripActive = false
        tripStartTime = nil
        tripEndTime = nil
        currentTripDistance = 0.0
        
        // Clear locations
        locations.removeAll()
        
        // Reset tracking state
        isTracking = false
        locationError = nil
        
        // IMPORTANT: Don't reset motion detection state
        // This allows automatic trip detection to continue working
        // speedDetectionStartTime will be reset when needed by the detection logic
        
        addLog("✅ Tracking state reset complete")
        addLog("ℹ️ Motion detection remains active for automatic trip detection")
    }

    func initializeAuthorizationStatus() {
        let logMessage = "Initializing authorization status"
        print("LocationManager: \(logMessage)")
        addLog(logMessage)
        
        // Reset tracking state to ensure clean start
        resetTrackingState()
        
        // Ensure motion detection is active
        setupMotionDetection()
        
        // Get the current status from the system to avoid initialization confusion
        let systemStatus = manager.authorizationStatus
        addLog("System authorization status: \(systemStatus.rawValue)")
        
        // Check current authorization status and log appropriately
        DispatchQueue.main.async {
            self.authorizationStatus = systemStatus
            
            if systemStatus.rawValue == 4 { // .authorizedAlways
                self.addLog("✅ Always authorization available - background tracking enabled")
                self.addLog("✅ Motion detection active - automatic trip detection enabled")
            } else if systemStatus.rawValue == 3 { // .authorizedWhenInUse
                self.addLog("✅ When In Use authorization available - tracking can be started")
                self.addLog("✅ Motion detection active - automatic trip detection enabled")
            } else if systemStatus.rawValue == 2 { // .denied
                self.addLog("❌ Location access denied - user needs to enable in Settings")
                self.locationError = "Location access denied"
            } else if systemStatus.rawValue == 1 { // .restricted
                self.addLog("❌ Location access restricted - cannot use location services")
                self.locationError = "Location access restricted"
            } else if systemStatus.rawValue == 0 { // .notDetermined
                self.addLog("⏳ Location permission not determined - checking current status...")
                // Don't auto-request permission - let user decide when to start tracking
                self.addLog("ℹ️ User can start tracking manually when ready")
            } else {
                self.addLog("❓ Unknown authorization status: \(systemStatus.rawValue)")
            }
        }
    }
    
    // MARK: - Motion Detection Management
    
    func restartMotionDetection() {
        addLog("🔄 Restarting motion detection")
        
        // Stop current motion detection
        motionManager.stopActivityUpdates()
        isMotionDetectionActive = false
        addLog("🔄 Stopped current motion detection")
        
        // Reset motion state
        lastAutomotiveActivityTime = nil
        speedDetectionStartTime = nil
        stopSpeedDetectionTimer()
        
        // Restart motion detection
        setupMotionDetection()
    }
    
    func getSpeedDetectionStatus() -> String {
        if let startTime = speedDetectionStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = max(0, speedDetectionDuration - elapsed)
            return "Active - \(String(format: "%.1f", remaining))s remaining"
        } else {
            return "Inactive"
        }
    }
    
    func getLocationTrackingStatus() -> String {
        if isTracking {
            let locationCount = locations.count
            if locationCount > 0 {
                let lastLocation = locations.last!
                let timeSinceLastUpdate = Date().timeIntervalSince(lastLocation.timestamp)
                return "Active - \(locationCount) locations, last update: \(String(format: "%.1f", timeSinceLastUpdate))s ago"
            } else {
                return "Active - Waiting for first GPS fix"
            }
        } else {
            return "Inactive"
        }
    }
    
    // MARK: - Debug State Information
    
    func logCurrentState() {
        addLog("🔍 === CURRENT STATE DEBUG ===")
        addLog("🔍 isTracking: \(isTracking)")
        addLog("🔍 isTripActive: \(isTripActive)")
        addLog("🔍 isMockMode: \(isMockMode)")
        addLog("🔍 locations.count: \(locations.count)")
        addLog("🔍 speedDetectionStartTime: \(speedDetectionStartTime?.description ?? "nil")")
        addLog("🔍 tripDetectionTimer: \(tripDetectionTimer != nil ? "active" : "nil")")
        addLog("🔍 authorizationStatus: \(authorizationStatus.rawValue)")
        addLog("🔍 isMotionDetectionActive: \(isMotionDetectionActive)")
        addLog("🔍 debugLogs.count: \(debugLogs.count)")
        addLog("🔍 === END STATE DEBUG ===")
    }
    
    // MARK: - System Health Monitoring
    
    func checkSystemHealth() {
        addLog("🏥 === SYSTEM HEALTH CHECK ===")
        
        // Check for excessive motion detection
        if isMotionDetectionActive {
            addLog("✅ Motion detection: Active")
        } else {
            addLog("⚠️ Motion detection: Inactive")
        }
        
        // Check for excessive logging
        if debugLogs.count > 40 {
            addLog("⚠️ High log count: \(debugLogs.count) - consider clearing logs")
        } else {
            addLog("✅ Log count: \(debugLogs.count) - healthy")
        }
        
        // Check for active timers
        var activeTimers = 0
        if tripDetectionTimer != nil { activeTimers += 1 }
        if autoStopTimer != nil { activeTimers += 1 }
        #if DEBUG
        if mockLocationTimer != nil { activeTimers += 1 }
        #endif
        
        addLog("⏰ Active timers: \(activeTimers)")
        
        addLog("🏥 === END HEALTH CHECK ===")
    }
    
    func refreshAuthorizationStatus() {
        let logMessage = "Refreshing authorization status"
        print("LocationManager: \(logMessage)")
        addLog(logMessage)
        
        // Get the current status from the system
        let currentStatus = manager.authorizationStatus
        addLog("System authorization status: \(currentStatus.rawValue)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = currentStatus
            
            if currentStatus.rawValue == 4 { // .authorizedAlways
                self.addLog("✅ Always authorization confirmed - background tracking available")
                self.addLog("✅ Motion detection active - automatic trip detection ready")
            } else if currentStatus.rawValue == 3 { // .authorizedWhenInUse
                self.addLog("✅ When In Use authorization confirmed - location tracking available")
                self.addLog("✅ Motion detection active - automatic trip detection ready")
            } else if currentStatus.rawValue == 2 { // .denied
                self.addLog("❌ Location access denied - user needs to enable in Settings")
                self.locationError = "Location access denied - enable in Settings"
            } else if currentStatus.rawValue == 1 { // .restricted
                self.addLog("❌ Location access restricted - cannot use location services")
                self.locationError = "Location access restricted"
            } else if currentStatus.rawValue == 0 { // .notDetermined
                self.addLog("⏳ Location permission not determined - user needs to grant access")
            } else {
                self.addLog("❓ Unknown authorization status: \(currentStatus.rawValue)")
            }
        }
    }
    
    func resetDistance() {
        let logMessage = "Resetting distance and clearing all locations"
        print("LocationManager: \(logMessage)")
        addLog(logMessage)
        
        DispatchQueue.main.async {
            self.locations.removeAll()
            self.locationError = nil
        }
    }
    
    #if DEBUG
    func addMockLocation() {
        guard isMockMode && isTracking else {
            addLog("❌ Cannot add mock location: Mock mode: \(isMockMode), Tracking: \(isTracking)")
            return
        }
        
        if mockLocationIndex < mockTrips[mockTripIndex].count {
            let mockLocation = mockTrips[mockTripIndex][mockLocationIndex]
            let latString = String(format: "%.4f", mockLocation.coordinate.latitude)
            let lonString = String(format: "%.4f", mockLocation.coordinate.longitude)
            
            addLog("📍 Manual Mock GPS \(mockLocationIndex + 1): \(latString), \(lonString)")
            
            DispatchQueue.main.async {
                self.locations.append(mockLocation)
                self.addLog("✅ Manually added mock location \(self.mockLocationIndex + 1) - Total locations: \(self.locations.count)")
            }
            
            mockLocationIndex += 1
        } else {
            addLog("✅ All mock locations for this trip have been added")
        }
    }
    
    // MARK: - Mock Mode Testing Helpers
    
    func simulateAutomotiveActivity() {
        addLog("🚗 Manually simulating automotive activity for testing")
        handleAutomotiveActivity()
    }
    
    func simulateNonAutomotiveActivity() {
        addLog("🚶 Manually simulating non-automotive activity for testing")
        handleNonAutomotiveActivity()
    }
    
    func getCurrentMockTripInfo() -> String {
        let tripNames = [
            "NYC to Queens (8.5 miles)",
            "Boston to Cambridge (3.2 miles)", 
            "San Francisco Loop (5.8 miles)",
            "Chicago Downtown (4.1 miles)"
        ]
        return tripNames[mockTripIndex]
    }
    
    func getMockTripCount() -> Int {
        return mockTrips.count
    }
    #endif
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations newLocations: [CLLocation]) {
        DispatchQueue.main.async {
            // Add new locations
            self.locations.append(contentsOf: newLocations)
            
            // Update current trip distance if trip is active
            if self.isTripActive {
                self.updateCurrentTripDistance()
            }
            
            // Update last movement time for auto-stop detection
            if let lastLocation = newLocations.last {
                self.lastMovementTime = lastLocation.timestamp
            }
            
            self.addLog("📍 Location update: \(newLocations.count) new points, total: \(self.locations.count)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let logMessage = "Location error: \(error.localizedDescription)"
        print("LocationManager: \(logMessage)")
        addLog(logMessage)
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let logMessage = "Authorization status changed to: \(status.rawValue)"
        print("LocationManager: \(logMessage)")
        addLog(logMessage)

        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            // CRITICAL: Use raw value comparison to avoid any enum comparison issues
            if status.rawValue == 4 { // .authorizedAlways
                self.addLog("🎉 Always authorization granted - background tracking enabled")
                // Enable background updates only after "Always" authorization
                self.manager.allowsBackgroundLocationUpdates = true
                self.addLog("✅ Background location updates enabled")
            } else if status.rawValue == 3 { // .authorizedWhenInUse
                self.addLog("🎉 When In Use authorization granted - location tracking available")
                self.addLog("✅ Motion detection active - automatic trip detection ready")
            } else if status.rawValue == 2 { // .denied
                self.addLog("❌ Location access denied by user")
                self.locationError = "Location access denied - enable in Settings"
            } else if status.rawValue == 1 { // .restricted
                self.addLog("❌ Location access restricted by system")
                self.locationError = "Location access restricted - cannot use location services"
            } else if status.rawValue == 0 { // .notDetermined
                self.addLog("⏳ Location permission not determined - waiting for user decision")
            } else {
                self.addLog("❓ Unknown authorization status: \(status.rawValue)")
            }
        }
    }
    
    private func updateCurrentTripDistance() {
        guard isTripActive, locations.count > 1 else { return }
        
        // Calculate distance from trip start to current
        if let startTime = tripStartTime {
            let tripLocations = locations.filter { $0.timestamp >= startTime }
            let newDistance = calculateDistance(locations: tripLocations)
            
            // Only update if distance actually changed
            if abs(newDistance - currentTripDistance) > 0.001 { // 0.001 mile threshold
                currentTripDistance = newDistance
                addLog("📏 Trip distance updated: \(String(format: "%.2f", currentTripDistance)) miles")
            }
        }
    }
    
    // MARK: - Distance Calculation
    
    private func calculateDistance(locations: [CLLocation]) -> Double {
        guard locations.count > 1 else { return 0 }
        
        var distance: Double = 0
        for i in 1..<locations.count {
            distance += locations[i].distance(from: locations[i-1])
        }
        
        // Convert meters to miles
        return distance / 1609.34
    }
    
    func calculateTotalDistance() -> Double {
        return calculateDistance(locations: locations)
    }
    
    // Helper method to calculate distance from saved test case location data
    private func calculateDistanceFromLocationData(_ locationData: [TestCase.LocationData]) -> Double {
        guard locationData.count > 1 else { return 0 }
        
        var distance: Double = 0
        for i in 1..<locationData.count {
            let prevLocation = CLLocation(latitude: locationData[i-1].latitude, longitude: locationData[i-1].longitude)
            let currLocation = CLLocation(latitude: locationData[i].latitude, longitude: locationData[i].longitude)
            distance += currLocation.distance(from: prevLocation)
        }
        
        // Convert meters to miles
        return distance / 1609.34
    }
}
