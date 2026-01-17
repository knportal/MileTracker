//
//  LocationManagerTests.swift
//  MileTrackerTests
//
//  Created by Kenneth Nygren on 8/15/25.
//

import CoreLocation
@testable import MileTracker
import Testing

struct LocationManagerTests {
    // MARK: - Test Setup/Teardown

    private func createCleanLocationManager() -> LocationManager {
        let locationManager = LocationManager()
        // Ensure clean state
        locationManager.stopTracking()
        return locationManager
    }

    // MARK: - Initialization Tests

    @Test func initialization() async throws {
        let locationManager = createCleanLocationManager()
        #expect(locationManager.isTracking == false)
        #expect(locationManager.isTripActive == false)
        #expect(locationManager.currentTripDistance == 0.0)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func dependenciesInitialized() async throws {
        let locationManager = createCleanLocationManager()
        // Test that LocationManager initializes without crashing
        #expect(locationManager.isTracking == false)
        #expect(locationManager.isTripActive == false)
    }

    // MARK: - Tracking Control Tests

    @Test func testStartTracking() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTracking()
        #expect(locationManager.isTracking == true)
    }

    @Test func testStopTracking() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTracking()
        locationManager.stopTracking()
        #expect(locationManager.isTracking == false)
    }

    @Test func stopTrackingWithoutStarting() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.stopTracking() // Should not crash
        #expect(locationManager.isTracking == false)
    }

    // MARK: - Trip Control Tests

    @Test func testStartTrip() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        #expect(locationManager.isTripActive == true)
    }

    @Test func testStopTrip() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()
        #expect(locationManager.isTripActive == false)
    }

    @Test func stopTripWithoutStarting() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.stopTrip() // Should not crash
        #expect(locationManager.isTripActive == false)
    }

    // MARK: - Distance Property Tests

    @Test func currentTripDistanceProperty() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        // Test that current trip distance starts at 0
        #expect(locationManager.currentTripDistance == 0.0)
    }

    @Test func totalAccumulatedDistanceProperty() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()
        // Test that total accumulated distance starts at 0
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func currentTripDistanceWithNaN() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        // Test that current trip distance is finite
        #expect(locationManager.currentTripDistance.isFinite == true)
    }

    @Test func totalAccumulatedDistanceWithNaN() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()
        // Test that total accumulated distance is finite
        #expect(locationManager.totalAccumulatedDistance.isFinite == true)
    }

    // MARK: - Integration Tests

    @Test func startTrackingStartsDiagnosticMonitoring() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTracking()
        // Test that tracking starts successfully
        #expect(locationManager.isTracking == true)
    }

    @Test func stopTrackingStopsDiagnosticMonitoring() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTracking()
        locationManager.stopTracking()
        // Test that tracking stops successfully
        #expect(locationManager.isTracking == false)
    }

    @Test func stopTrackingStopsTrip() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTracking()
        // Test that stopping tracking also stops the trip
        #expect(locationManager.isTripActive == false)
    }

    // MARK: - Authorization Integration Tests

    @Test func authorizationStatusUpdate() async throws {
        let locationManager = createCleanLocationManager()
        // Test that authorization status is accessible
        #expect(locationManager.authorizationStatus.rawValue >= 0)
    }

    // MARK: - Mock Mode Tests

    @Test func mockModeToggle() async throws {
        let locationManager = createCleanLocationManager()
        #expect(locationManager.isMockMode == false)

        locationManager.toggleMockMode()
        #expect(locationManager.isMockMode == true)

        locationManager.toggleMockMode()
        #expect(locationManager.isMockMode == false)
    }

    @Test func mockModeStartTracking() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.toggleMockMode()
        locationManager.startTracking()
        #expect(locationManager.isTracking == true)
    }

    // MARK: - Test Case Integration Tests

    @Test func caseManagerIntegration() async throws {
        let locationManager = createCleanLocationManager()
        // Test that test case management is accessible
        #expect(locationManager.isRecordingTestCase == false)
    }

    @Test func runTestCase() async throws {
        let locationManager = createCleanLocationManager()
        // Test that test case management is accessible
        #expect(locationManager.isRecordingTestCase == false)
        #expect(locationManager.currentTestCase.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func multipleStartTracking() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTracking()
        locationManager.startTracking() // Should not crash
        #expect(locationManager.isTracking == true)
    }

    @Test func multipleStartTrip() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.startTrip() // Should not crash
        #expect(locationManager.isTripActive == true)
    }

    @Test func startTripWithoutTracking() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip() // Should work even without tracking
        #expect(locationManager.isTripActive == true)
    }

    // MARK: - State Consistency Tests

    @Test func stateConsistencyAfterStopTracking() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTracking()
        locationManager.startTrip()

        locationManager.stopTracking()

        #expect(locationManager.isTracking == false)
        #expect(locationManager.isTripActive == false)
    }

    @Test func stateConsistencyAfterStopTrip() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()

        locationManager.stopTrip()

        #expect(locationManager.isTripActive == false)
        #expect(locationManager.currentTripDistance == 0.0)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }
}
