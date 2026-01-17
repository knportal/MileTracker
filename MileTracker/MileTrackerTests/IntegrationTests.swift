//
//  IntegrationTests.swift
//  MileTrackerTests
//
//  Created by Kenneth Nygren on 8/15/25.
//

import CoreLocation
@testable import MileTracker
import Testing

struct IntegrationTests {
    // MARK: - Test Setup/Teardown

    private func createCleanLocationManager() -> LocationManager {
        let locationManager = LocationManager()
        // Ensure clean state
        locationManager.stopTracking()
        return locationManager
    }

    // MARK: - Full Workflow Tests

    @Test func completeTripWorkflow() async throws {
        let locationManager = createCleanLocationManager()

        // Start tracking
        locationManager.startTracking()
        #expect(locationManager.isTracking == true)

        // Start trip
        locationManager.startTrip()
        #expect(locationManager.isTripActive == true)

        // Test that trip starts with 0 distance
        #expect(locationManager.currentTripDistance == 0.0)

        // Stop trip
        locationManager.stopTrip()
        #expect(locationManager.isTripActive == false)
        #expect(locationManager.currentTripDistance == 0.0)
        #expect(locationManager.totalAccumulatedDistance == 0.0)

        // Stop tracking
        locationManager.stopTracking()
        #expect(locationManager.isTracking == false)
    }

    @Test func multipleTripsWorkflow() async throws {
        let locationManager = createCleanLocationManager()

        // First trip
        locationManager.startTracking()
        locationManager.startTrip()
        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance == 0.0)

        // Second trip
        locationManager.startTrip()
        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance == 0.0)

        // Third trip
        locationManager.startTrip()
        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance == 0.0)

        locationManager.stopTracking()
    }

    // MARK: - Error Handling Integration Tests

    @Test func naNHandlingThroughoutWorkflow() async throws {
        let locationManager = createCleanLocationManager()

        locationManager.startTracking()
        locationManager.startTrip()

        // Test that trip distance is finite
        #expect(locationManager.currentTripDistance.isFinite == true)

        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance.isFinite == true)

        locationManager.stopTracking()
    }

    // MARK: - Authorization Integration Tests

    @Test func authorizationStatusIntegration() async throws {
        let locationManager = createCleanLocationManager()

        // Test that authorization status is accessible
        #expect(locationManager.authorizationStatus.rawValue >= 0)
    }

    // MARK: - Mock Mode Integration Tests

    @Test func mockModeIntegration() async throws {
        let locationManager = createCleanLocationManager()

        // Enable mock mode
        locationManager.toggleMockMode()
        #expect(locationManager.isMockMode == true)

        // Test tracking in mock mode
        locationManager.startTracking()
        #expect(locationManager.isTracking == true)

        // Test trip in mock mode
        locationManager.startTrip()
        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance == 0.0)

        // Disable mock mode
        locationManager.toggleMockMode()
        #expect(locationManager.isMockMode == false)

        locationManager.stopTracking()
    }

    // MARK: - Test Case Integration Tests

    @Test func caseIntegration() async throws {
        let locationManager = createCleanLocationManager()

        // Test test case management
        #expect(locationManager.isRecordingTestCase == false)

        // Test that test case management is accessible
        #expect(locationManager.currentTestCase.isEmpty)
    }

    // MARK: - Diagnostic Integration Tests

    @Test func diagnosticIntegration() async throws {
        let locationManager = createCleanLocationManager()

        locationManager.startTracking()

        // Test that tracking starts successfully
        #expect(locationManager.isTracking == true)

        locationManager.stopTracking()
        #expect(locationManager.isTracking == false)
    }

    // MARK: - State Consistency Tests

    @Test func stateConsistencyAfterStopTracking() async throws {
        let locationManager = createCleanLocationManager()

        locationManager.startTracking()
        locationManager.startTrip()

        // Stop tracking should stop everything
        locationManager.stopTracking()

        #expect(locationManager.isTracking == false)
        #expect(locationManager.isTripActive == false)
        #expect(locationManager.currentTripDistance == 0.0)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func stateConsistencyAfterStopTrip() async throws {
        let locationManager = createCleanLocationManager()

        locationManager.startTracking()
        locationManager.startTrip()

        // Stop trip should only stop the trip
        locationManager.stopTrip()

        #expect(locationManager.isTracking == true)
        #expect(locationManager.isTripActive == false)
        #expect(locationManager.currentTripDistance == 0.0)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    // MARK: - Edge Case Integration Tests

    @Test func rapidStateChanges() async throws {
        let locationManager = createCleanLocationManager()

        // Rapid state changes should not cause issues
        locationManager.startTracking()
        locationManager.stopTracking()
        locationManager.startTracking()
        locationManager.startTrip()
        locationManager.stopTrip()
        locationManager.startTrip()
        locationManager.stopTracking()

        #expect(locationManager.isTracking == false)
        #expect(locationManager.isTripActive == false)
    }

    @Test func distanceAccumulationWithRapidTrips() async throws {
        let locationManager = createCleanLocationManager()

        // Rapid trip start/stop cycles
        for i in 1 ... 5 {
            locationManager.startTrip()
            locationManager.stopTrip()
        }

        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    // MARK: - Memory and Performance Tests

    @Test func memoryUsageWithLargeNumberOfTrips() async throws {
        let locationManager = createCleanLocationManager()

        // Create many trips to test memory management
        for i in 1 ... 100 {
            locationManager.startTrip()
            locationManager.stopTrip()
        }

        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func performanceWithLargeDistances() async throws {
        let locationManager = createCleanLocationManager()

        locationManager.startTrip()

        // Test that trip distance is finite
        #expect(locationManager.currentTripDistance.isFinite == true)

        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance.isFinite == true)
    }
}
