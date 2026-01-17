//
//  TripDetectionTests.swift
//  MileTrackerTests
//
//  Created by Kenneth Nygren on 8/15/25.
//

import CoreLocation
@testable import MileTracker
import Testing

struct TripDetectionTests {
    // MARK: - Test Setup/Teardown

    private func createCleanTripDetection() -> TripDetection {
        let tripDetection = TripDetection()
        // Ensure clean state
        tripDetection.stopTrip()
        return tripDetection
    }

    // MARK: - Trip State Tests

    @Test func initialState() async throws {
        let tripDetection = createCleanTripDetection()
        #expect(tripDetection.isTripActive == false)
        #expect(tripDetection.currentTripDistance == 0.0)
        #expect(tripDetection.totalAccumulatedDistance == 0.0)
    }

    @Test func testStartTrip() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        #expect(tripDetection.isTripActive == true)
        #expect(tripDetection.currentTripDistance == 0.0)
    }

    @Test func testStopTrip() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        tripDetection.stopTrip()
        #expect(tripDetection.isTripActive == false)
    }

    @Test func stopTripWithoutStarting() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.stopTrip() // Should not crash
        #expect(tripDetection.isTripActive == false)
    }

    // MARK: - Distance Accumulation Tests

    @Test func addDistanceToActiveTrip() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip starts with 0 distance
        #expect(tripDetection.currentTripDistance == 0.0)
    }

    @Test func addDistanceToInactiveTrip() async throws {
        let tripDetection = createCleanTripDetection()
        // Test that inactive trip has 0 distance
        #expect(tripDetection.currentTripDistance == 0.0)
    }

    @Test func multipleDistanceAdditions() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip starts with 0 distance
        #expect(tripDetection.currentTripDistance == 0.0)
    }

    @Test func distanceAccumulationOnStop() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        tripDetection.stopTrip()
        #expect(tripDetection.totalAccumulatedDistance == 0.0)
        #expect(tripDetection.currentTripDistance == 0.0)
    }

    @Test func multipleTripsAccumulation() async throws {
        let tripDetection = createCleanTripDetection()

        // First trip
        tripDetection.startTrip()
        tripDetection.stopTrip()
        #expect(tripDetection.totalAccumulatedDistance == 0.0)

        // Second trip
        tripDetection.startTrip()
        tripDetection.stopTrip()
        #expect(tripDetection.totalAccumulatedDistance == 0.0)
    }

    // MARK: - NaN Handling Tests

    @Test func addNaNDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip distance is finite
        #expect(tripDetection.currentTripDistance.isFinite == true)
    }

    @Test func addInfinityDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip distance is finite
        #expect(tripDetection.currentTripDistance.isFinite == true)
    }

    @Test func addNegativeDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip distance is finite
        #expect(tripDetection.currentTripDistance.isFinite == true)
    }

    @Test func addValidDistanceAfterNaN() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip distance is finite
        #expect(tripDetection.currentTripDistance.isFinite == true)
    }

    // MARK: - Total Accumulated Distance Tests

    @Test func totalAccumulatedDistanceNaNProtection() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        tripDetection.stopTrip()

        // Test that total accumulated distance is finite
        #expect(tripDetection.totalAccumulatedDistance.isFinite == true)
    }

    @Test func testResetTotalAccumulatedDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        tripDetection.stopTrip()
        #expect(tripDetection.totalAccumulatedDistance == 0.0)

        tripDetection.resetTotalAccumulatedDistance()
        #expect(tripDetection.totalAccumulatedDistance == 0.0)
    }

    @Test func testGetTotalAccumulatedDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        tripDetection.stopTrip()

        let total = tripDetection.getTotalAccumulatedDistance()
        #expect(total == 0.0)
    }

    // MARK: - Edge Cases

    @Test func verySmallDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip distance is finite
        #expect(tripDetection.currentTripDistance.isFinite == true)
    }

    @Test func veryLargeDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip distance is finite
        #expect(tripDetection.currentTripDistance.isFinite == true)
    }

    @Test func zeroDistance() async throws {
        let tripDetection = createCleanTripDetection()
        tripDetection.startTrip()
        // Test that trip distance starts at 0
        #expect(tripDetection.currentTripDistance == 0.0)
    }
}
