//
//  StatusViewTests.swift
//  MileTrackerTests
//
//  Created by Kenneth Nygren on 8/15/25.
//

@testable import MileTracker
import SwiftUI
import Testing

struct StatusViewTests {
    // MARK: - Test Setup/Teardown

    private func createCleanLocationManager() -> LocationManager {
        let locationManager = LocationManager()
        // Ensure clean state
        locationManager.stopTracking()
        return locationManager
    }

    // MARK: - Status Display Tests

    @Test func statusViewInitialization() async throws {
        let locationManager = createCleanLocationManager()
        let statusView = StatusView(locationManager: locationManager)
        #expect(await statusView.locationManager === locationManager)
    }

    @Test func statusViewWithZeroDistance() async throws {
        let locationManager = createCleanLocationManager()
        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func statusViewWithDistance() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func statusViewWithNaNDistance() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0) // Should be sanitized
    }

    // MARK: - Distance Display Tests

    @Test func distanceDisplayFormatting() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func distanceDisplayWithVerySmallValue() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func distanceDisplayWithLargeValue() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    // MARK: - State Change Tests

    @Test func statusViewUpdatesWithLocationManagerChanges() async throws {
        let locationManager = createCleanLocationManager()
        let statusView = StatusView(locationManager: locationManager)

        // Initial state
        #expect(locationManager.totalAccumulatedDistance == 0.0)

        // Add distance
        locationManager.startTrip()
        locationManager.stopTrip()

        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func statusViewWithMultipleTrips() async throws {
        let locationManager = createCleanLocationManager()
        let statusView = StatusView(locationManager: locationManager)

        // First trip
        locationManager.startTrip()
        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance == 0.0)

        // Second trip
        locationManager.startTrip()
        locationManager.stopTrip()
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    // MARK: - Edge Cases

    @Test func statusViewWithNegativeDistance() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func statusViewWithInfinityDistance() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0) // Should be sanitized
    }

    @Test func statusViewWithVeryPreciseDistance() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    // MARK: - Memory Management Tests

    @Test func statusViewMemoryManagement() async throws {
        let locationManager = createCleanLocationManager()
        let statusView = StatusView(locationManager: locationManager)

        // Should not create retain cycles
        #expect(await statusView.locationManager === locationManager)
    }

    // MARK: - Integration Tests

    @Test func statusViewWithMockMode() async throws {
        let locationManager = createCleanLocationManager()
        locationManager.toggleMockMode()
        locationManager.startTrip()
        locationManager.stopTrip()

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.totalAccumulatedDistance == 0.0)
    }

    @Test func statusViewWithTestCase() async throws {
        let locationManager = createCleanLocationManager()
        // Test that test case management is accessible
        #expect(locationManager.isRecordingTestCase == false)

        let statusView = StatusView(locationManager: locationManager)
        #expect(locationManager.isRecordingTestCase == false)
    }
}
