import CoreLocation
import CoreMotion
import Foundation

// MARK: - Diagnostic Data Structures

struct DiagnosticIssue: Identifiable, Codable {
    let id: UUID
    let severity: IssueSeverity
    let category: IssueCategory
    let timestamp: Date
    let description: String
    let impact: String
    let recommendation: String
    let data: [String: String] // Additional context

    init(
        severity: IssueSeverity,
        category: IssueCategory,
        description: String,
        impact: String,
        recommendation: String,
        data: [String: String] = [:]
    ) {
        self.id = UUID()
        self.severity = severity
        self.category = category
        self.timestamp = Date()
        self.description = description
        self.impact = impact
        self.recommendation = recommendation
        self.data = data
    }

    enum IssueSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }

    enum IssueCategory: String, Codable, CaseIterable {
        case gps = "GPS Issues"
        case performance = "Performance Issues"
        case system = "System Issues"
        case battery = "Battery Issues"
        case dataQuality = "Data Quality Issues"
    }
}

struct MemorySnapshot: Codable {
    let timestamp: Date
    let memoryUsage: Int64
    let availableMemory: Int64
}

struct BatterySnapshot: Codable {
    let timestamp: Date
    let batteryLevel: Float
    let isCharging: Bool
    let powerMode: String
}

struct GPSQualitySnapshot: Codable {
    let timestamp: Date
    let accuracy: Double
    let speed: Double?
    let altitude: Double?
    let course: Double?
    let signalStrength: Int?
}

struct SystemStateSnapshot: Codable {
    let timestamp: Date
    let authorizationStatus: Int
    let backgroundLocationAvailable: Bool
    let motionDetectionActive: Bool
    let lowPowerMode: Bool
    let backgroundAppRefresh: Bool
}

// MARK: - Test Case Structures

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
    let diagnosticData: DiagnosticData?

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
        let distance: Double // Distance in miles
        let duration: TimeInterval
    }

    struct DeviceInfo: Codable {
        let model: String
        let systemVersion: String
        let appVersion: String
        let buildNumber: String
    }
}

// MARK: - Diagnostic Data Structure

struct DiagnosticData: Codable {
    let issues: [DiagnosticIssue]
    let memorySnapshots: [MemorySnapshot]
    let batterySnapshots: [BatterySnapshot]
    let gpsQualitySnapshots: [GPSQualitySnapshot]
    let systemStateSnapshots: [SystemStateSnapshot]
}

// MARK: - Trip Detection Models

struct TripDetectionConfig {
    let speedThreshold: Double = 5.0 // mph
    let speedDetectionDuration: TimeInterval = 15.0 // seconds
    let autoStopDuration: TimeInterval = 1800.0 // 30 minutes - more reasonable for real trips
}

// MARK: - Location Processing Models

struct LocationProcessingMetrics {
    let processingTime: TimeInterval
    let accuracy: Double
    let speed: Double?
    let timestamp: Date
}

// MARK: - Mock Data Models

#if DEBUG
    struct MockTripData {
        let locations: [CLLocation]
        let tripName: String
        let expectedDistance: Double // Expected distance in miles
        let expectedDuration: TimeInterval
    }
#endif
