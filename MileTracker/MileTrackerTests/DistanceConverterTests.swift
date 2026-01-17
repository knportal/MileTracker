//
//  DistanceConverterTests.swift
//  MileTrackerTests
//
//  Created by Kenneth Nygren on 8/15/25.
//

import CoreLocation
@testable import MileTracker
import Testing

struct DistanceConverterTests {
    // MARK: - Distance Conversion Tests

    @Test func testMetersToMiles() async throws {
        let meters = 1609.34 // 1 mile in meters
        let miles = DistanceConverter.metersToMiles(meters)
        #expect(miles > 0.999 && miles < 1.001) // Allow small floating point precision
    }

    @Test func testMetersToKilometers() async throws {
        let meters = 1000.0
        let kilometers = DistanceConverter.metersToKilometers(meters)
        #expect(kilometers == 1.0)
    }

    @Test func testMilesToMeters() async throws {
        let miles = 1.0
        let meters = DistanceConverter.milesToMeters(miles)
        #expect(meters > 1609.0 && meters < 1610.0) // 1 mile ≈ 1609.34 meters
    }

    // MARK: - Distance Formatting Tests

    @Test func testFormatDistanceInMiles() async throws {
        let miles = 1.5
        let formatted = DistanceConverter.formatDistanceInMiles(miles)
        #expect(formatted == "1.50 mi")
    }

    @Test func testFormatDistanceInMeters() async throws {
        let meters = 2300.0
        let formatted = DistanceConverter.formatDistanceInMeters(meters)
        #expect(formatted == "2.3 km")
    }

    @Test func formatDistanceInMetersSmall() async throws {
        let meters = 500.0
        let formatted = DistanceConverter.formatDistanceInMeters(meters)
        #expect(formatted == "500 m")
    }

    @Test func formatDistanceZero() async throws {
        let formatted = DistanceConverter.formatDistance(0.0)
        #expect(formatted == "0.00 mi")
    }

    // MARK: - NaN Handling Tests

    @Test func sanitizeDistanceWithValidValue() async throws {
        let validDistance = 5.5
        let sanitized = DistanceConverter.sanitizeDistance(validDistance)
        #expect(sanitized == 5.5)
    }

    @Test func sanitizeDistanceWithNaN() async throws {
        let nanDistance = Double.nan
        let sanitized = DistanceConverter.sanitizeDistance(nanDistance)
        #expect(sanitized == 0.0)
    }

    @Test func sanitizeDistanceWithInfinity() async throws {
        let infinityDistance = Double.infinity
        let sanitized = DistanceConverter.sanitizeDistance(infinityDistance)
        #expect(sanitized == 0.0)
    }

    @Test func sanitizeDistanceWithNegativeInfinity() async throws {
        let negativeInfinityDistance = -Double.infinity
        let sanitized = DistanceConverter.sanitizeDistance(negativeInfinityDistance)
        #expect(sanitized == 0.0)
    }

    // MARK: - Location Distance Filter Tests

    @Test func testGetLocationDistanceFilter() async throws {
        let filter = DistanceConverter.getLocationDistanceFilter()
        #expect(filter > 0) // Should be a positive value
        #expect(filter <= 100) // Should be reasonable for location tracking
    }

    // MARK: - Edge Cases

    @Test func verySmallDistance() async throws {
        let verySmall = 0.0001
        let sanitized = DistanceConverter.sanitizeDistance(verySmall)
        #expect(sanitized == verySmall)
    }

    @Test func veryLargeDistance() async throws {
        let veryLarge = 1_000_000.0
        let sanitized = DistanceConverter.sanitizeDistance(veryLarge)
        #expect(sanitized == veryLarge)
    }

    @Test func negativeDistance() async throws {
        let negative: Double = -5.0
        let sanitized = DistanceConverter.sanitizeDistance(negative)
        #expect(sanitized == 0.0) // Negative distances should be sanitized to 0
    }

    // MARK: - Additional API Tests

    @Test func testIsValidDistance() async throws {
        #expect(DistanceConverter.isValidDistance(5.0) == true)
        #expect(DistanceConverter.isValidDistance(0.0) == true)
        #expect(DistanceConverter.isValidDistance(-1.0) == false)
        #expect(DistanceConverter.isValidDistance(Double.nan) == false)
        #expect(DistanceConverter.isValidDistance(Double.infinity) == false)
    }

    @Test func testKilometersToMeters() async throws {
        let kilometers = 2.5
        let meters = DistanceConverter.kilometersToMeters(kilometers)
        #expect(meters == 2500.0)
    }

    @Test func formatDistanceWithMeters() async throws {
        let meters = 1609.344 // 1 mile
        let formatted = DistanceConverter.formatDistance(meters)
        #expect(formatted == "1.00 mi")
    }

    @Test func testDebugDistanceInfo() async throws {
        let meters = 1000.0
        let debugInfo = DistanceConverter.debugDistanceInfo(meters)
        #expect(debugInfo.contains("1000.000"))
        #expect(debugInfo.contains("0.621371"))
        #expect(debugInfo.contains("1.000"))
    }
}
