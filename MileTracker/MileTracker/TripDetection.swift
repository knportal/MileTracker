import Combine
import CoreLocation
import Foundation

class TripDetection: ObservableObject {
    // MARK: - Published Properties

    @Published var isTripActive = false
    @Published var tripStartTime: Date?
    @Published var tripEndTime: Date?
    @Published var currentTripDistance: Double = 0.0 {
        didSet {
            // CRITICAL FIX: Ensure distance never becomes NaN
            if !currentTripDistance.isFinite {
                currentTripDistance = 0.0
                addLog("⚠️ Distance reset to 0 due to invalid value")
            }
        }
    }

    // Total accumulated distance across all trips (persists across trip resets)
    @Published var totalAccumulatedDistance: Double = 0.0 {
        didSet {
            // CRITICAL FIX: Ensure total distance never becomes NaN
            if !totalAccumulatedDistance.isFinite {
                totalAccumulatedDistance = 0.0
                addLog("⚠️ Total distance reset to 0 due to invalid value")
            }
        }
    }

    // MARK: - Private Properties

    private var speedDetectionStartTime: Date?
    private var lastMovementTime: Date?
    private var config = TripDetectionConfig()

    // Timers
    private var tripDetectionTimer: Timer?
    private var autoStopTimer: Timer?

    // Location tracking
    private var lastLocation: CLLocation?
    private var tripLocations: [CLLocation] = []

    // MARK: - Public Methods

    func startTripDetection() {
        addLog("🚗 Trip detection started")
        tripDetectionTimer = Timer
            .scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.checkForTripStart()
            }
    }

    func stopTripDetection() {
        tripDetectionTimer?.invalidate()
        tripDetectionTimer = nil

        // Also stop auto-stop timer to prevent test isolation issues
        autoStopTimer?.invalidate()
        autoStopTimer = nil

        addLog("🚗 Trip detection stopped")
    }

    func processLocation(_ location: CLLocation) {
        // Update trip distance if trip is active
        if isTripActive, let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)

            // IMPROVED: Add GPS accuracy filtering to prevent wild jumps
            let maxReasonableDistance = 1000.0 // 1km max between consecutive points
            let timeDifference = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            let maxReasonableSpeed = 200.0 // 200 m/s max speed (720 km/h)
            let maxDistanceForTime = timeDifference * maxReasonableSpeed

            // CRITICAL FIX: Validate distance to prevent NaN values and GPS jumps
            if distance.isFinite, distance >= 0, distance <= maxReasonableDistance,
               distance <= maxDistanceForTime {
                currentTripDistance += distance
                tripLocations.append(location)
                addLog(
                    "📍 Distance added: \(DistanceConverter.formatDistanceInMiles(DistanceConverter.metersToMiles(distance))), Total: \(DistanceConverter.formatDistanceInMiles(DistanceConverter.metersToMiles(currentTripDistance)))"
                )

                // Reset auto-stop timer when movement is detected
                resetAutoStopTimer()
            } else {
                let reason = !distance.isFinite ? "NaN" :
                    distance < 0 ? "negative" :
                    distance > maxReasonableDistance ?
                    "too large (\(String(format: "%.1f", distance))m)" :
                    distance > maxDistanceForTime ? "impossible speed" : "unknown"
                addLog("⚠️ Invalid distance detected: \(reason), skipping update")
            }
        }

        lastLocation = location
        lastMovementTime = Date()

        // Check for trip start only - let the auto-stop timer handle trip stopping
        checkForTripStart()
    }

    func startTrip() {
        guard !isTripActive else {
            addLog("🚗 Trip start requested but trip already active")
            return
        }

        isTripActive = true
        tripStartTime = Date()
        currentTripDistance = 0.0
        tripLocations.removeAll()

        addLog("🚗 Trip started at \(formatTime(tripStartTime ?? Date())) - Distance reset to 0.0")

        // Start auto-stop timer
        startAutoStopTimer()
    }

    func stopTrip() {
        guard isTripActive else {
            addLog("🚗 Trip stop requested but no trip active")
            return
        }

        isTripActive = false
        tripEndTime = Date()

        let safeDistance = currentTripDistance.isFinite ? currentTripDistance : 0.0
        let duration = tripStartTime != nil ? (tripEndTime ?? Date())
            .timeIntervalSince(tripStartTime ?? Date()) : 0.0

        // CRITICAL FIX: Accumulate trip distance into total before resetting
        // Ensure both values are finite before addition
        let safeTotal = totalAccumulatedDistance.isFinite ? totalAccumulatedDistance : 0.0
        totalAccumulatedDistance = safeTotal + safeDistance

        addLog("🚗 Trip stopped at \(formatTime(tripEndTime ?? Date()))")
        addLog("🚗 Trip duration: \(String(format: "%.1f", duration)) seconds")
        addLog(
            "🚗 Trip distance: \(DistanceConverter.formatDistanceInMiles(DistanceConverter.metersToMiles(safeDistance)))"
        )
        addLog(
            "🚗 Total accumulated: \(DistanceConverter.formatDistanceInMiles(DistanceConverter.metersToMiles(totalAccumulatedDistance)))"
        )
        addLog("🚗 Location points: \(tripLocations.count)")

        // Stop auto-stop timer
        autoStopTimer?.invalidate()
        autoStopTimer = nil
    }

    func resetTrip() {
        isTripActive = false
        tripStartTime = nil
        tripEndTime = nil
        currentTripDistance = 0.0
        tripLocations.removeAll()
        lastLocation = nil

        autoStopTimer?.invalidate()
        autoStopTimer = nil

        addLog("🚗 Trip reset")
    }

    // Get total accumulated distance across all trips
    func getTotalAccumulatedDistance() -> Double {
        return totalAccumulatedDistance.isFinite ? totalAccumulatedDistance : 0.0
    }

    // Reset total accumulated distance (for testing or user request)
    func resetTotalAccumulatedDistance() {
        totalAccumulatedDistance = 0.0
        addLog("🚗 Total accumulated distance reset to 0")
    }

    // MARK: - Private Methods

    private func checkForTripStart() {
        guard !isTripActive else { return }

        if let lastMovementTime = lastMovementTime {
            let timeSinceLastMovement = Date().timeIntervalSince(lastMovementTime)

            if timeSinceLastMovement <= config.speedDetectionDuration {
                if speedDetectionStartTime == nil {
                    speedDetectionStartTime = Date()
                }

                let detectionDuration = Date().timeIntervalSince(speedDetectionStartTime ?? Date())
                if detectionDuration >= config.speedDetectionDuration {
                    startTrip()
                }
            } else {
                speedDetectionStartTime = nil
            }
        }
    }

    // REMOVED: checkForTripStop() method was causing premature trip termination
    // The auto-stop timer now handles trip stopping exclusively

    private func startAutoStopTimer() {
        // Cancel any existing timer
        autoStopTimer?.invalidate()

        autoStopTimer = Timer.scheduledTimer(
            withTimeInterval: config.autoStopDuration,
            repeats: false
        ) { [weak self] _ in
            self?.stopTrip()
        }
        addLog("⏰ Auto-stop timer started (1800 seconds / 30 minutes)")
    }

    private func resetAutoStopTimer() {
        // Reset the auto-stop timer when movement is detected
        if isTripActive {
            startAutoStopTimer()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func addLog(_ message: String) {
        print("🚗 [TripDetection] \(message)")
    }

    // MARK: - Trip Data Access

    func getTripDuration() -> TimeInterval? {
        guard let startTime = tripStartTime else { return nil }
        let endTime = tripEndTime ?? Date()
        return endTime.timeIntervalSince(startTime)
    }

    func getTripLocations() -> [CLLocation] {
        return tripLocations
    }

    func getTripData() -> TestCase.TripData? {
        guard let startTime = tripStartTime else { return nil }

        return TestCase.TripData(
            isActive: isTripActive,
            startTime: startTime,
            endTime: tripEndTime,
            distance: DistanceConverter.metersToMiles(currentTripDistance),
            duration: getTripDuration() ?? 0
        )
    }
}
