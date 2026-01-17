import CoreLocation
import Foundation
import UIKit

class TestCaseManager: ObservableObject {
    // MARK: - Published Properties

    @Published var currentTestCase: String = "Default Test"
    @Published var testCaseNotes: String = ""
    @Published var savedTestCases: [TestCase] = []
    @Published var isRecordingTestCase = false

    // MARK: - Private Properties

    private var testCaseStartTime: Date?
    private var testCaseLogs: [String] = []
    private var testCaseLocations: [TestCase.LocationData] = []

    // MARK: - Dependencies

    private var diagnosticManager: DiagnosticManager?
    private var locationManager: LocationManager?

    // MARK: - Debug Logs Integration

    private var capturedDebugLogs: [String] = []
    private var debugLogStartTime: Date?

    // MARK: - Public Methods

    func setDependencies(diagnosticManager: DiagnosticManager, locationManager: LocationManager) {
        self.diagnosticManager = diagnosticManager
        self.locationManager = locationManager
        addLog("🧪 Dependencies set for test case management")
    }

    func startTestCase(name: String, notes: String = "") {
        guard !isRecordingTestCase else { return }

        currentTestCase = name
        testCaseNotes = notes
        isRecordingTestCase = true
        testCaseStartTime = Date()
        testCaseLogs.removeAll()
        testCaseLocations.removeAll()

        // Start capturing debug logs
        startDebugLogCapture()

        addLog("🧪 Test case started: \(name)")
        if !notes.isEmpty {
            addLog("📝 Notes: \(notes)")
        }
    }

    func stopTestCase() {
        guard isRecordingTestCase else { return }

        isRecordingTestCase = false
        let endTime = Date()

        addLog("🧪 Test case stopped: \(currentTestCase)")

        // Stop capturing debug logs
        stopDebugLogCapture()

        // Create and save test case with diagnostic data
        let testCase = createTestCase(endTime: endTime)
        savedTestCases.append(testCase)

        // Reset state
        testCaseStartTime = nil
        testCaseLogs.removeAll()
        testCaseLocations.removeAll()
        capturedDebugLogs.removeAll()
    }

    func addTestCaseLog(_ message: String) {
        guard isRecordingTestCase else { return }
        testCaseLogs.append("\(formatTime(Date())): \(message)")
    }

    func addTestCaseLocation(_ location: CLLocation) {
        guard isRecordingTestCase else { return }

        let locationData = TestCase.LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            accuracy: location.horizontalAccuracy
        )

        testCaseLocations.append(locationData)
    }

    func clearAllTestCases() {
        savedTestCases.removeAll()
        addLog("🧪 All test cases cleared")
    }

    func exportTestCases() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        // Create a custom date formatter for readable timestamps
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Create a custom encoding strategy for dates
        encoder.dateEncodingStrategy = .formatted(dateFormatter)

        do {
            let data = try encoder.encode(savedTestCases)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            addLog("❌ Failed to export test cases: \(error.localizedDescription)")
            return "[]"
        }
    }

    func exportAllTestCases() {
        let exportData = exportTestCases()

        // Create a comprehensive export with debug logs and diagnostic data
        var fullExport = "=== MILE TRACKER TEST CASE EXPORT ===\n"
        fullExport += "Export Date: \(DateFormatter().string(from: Date()))\n"
        fullExport += "Total Test Cases: \(savedTestCases.count)\n\n"

        // Add test case summary
        fullExport += "=== TEST CASE SUMMARY ===\n"
        fullExport += getTestCaseSummary()
        fullExport += "\n\n"

        // Add detailed test case data
        fullExport += "=== DETAILED TEST CASE DATA ===\n"
        fullExport += exportData
        fullExport += "\n\n"

        // Share the export
        shareExportData(fullExport)
    }

    func exportAllTestCasesWithDiagnostics(_ diagnosticIssues: [DiagnosticIssue]) {
        let exportData = exportTestCases()

        // Create a comprehensive export with debug logs and diagnostic data
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .medium

        var fullExport = "=== MILE TRACKER TEST CASE EXPORT ===\n"
        fullExport += "Export Date: \(dateFormatter.string(from: Date()))\n"
        fullExport += "Total Test Cases: \(savedTestCases.count)\n\n"

        // Add test case summary
        fullExport += "=== TEST CASE SUMMARY ===\n"
        fullExport += getTestCaseSummary()
        fullExport += "\n\n"

        // Add detailed test case data
        fullExport += "=== DETAILED TEST CASE DATA ===\n"
        fullExport += exportData
        fullExport += "\n\n"

        // Add comprehensive diagnostic data from saved test cases
        fullExport += "=== COMPREHENSIVE DIAGNOSTIC DATA ===\n"
        for (index, testCase) in savedTestCases.enumerated() {
            fullExport += "Test Case \(index + 1): \(testCase.name)\n"

            if let diagnosticData = testCase.diagnosticData {
                fullExport += "  Diagnostic Issues: \(diagnosticData.issues.count)\n"
                fullExport += "  Memory Snapshots: \(diagnosticData.memorySnapshots.count)\n"
                fullExport += "  Battery Snapshots: \(diagnosticData.batterySnapshots.count)\n"
                fullExport += "  GPS Quality Snapshots: \(diagnosticData.gpsQualitySnapshots.count)\n"
                fullExport += "  System State Snapshots: \(diagnosticData.systemStateSnapshots.count)\n"

                if !diagnosticData.issues.isEmpty {
                    fullExport += "  Issues:\n"
                    for issue in diagnosticData.issues {
                        fullExport += "    • \(issue.severity.rawValue): \(issue.description)\n"
                        fullExport += "      Category: \(issue.category.rawValue)\n"
                        fullExport += "      Impact: \(issue.impact)\n"
                    }
                }
            } else {
                fullExport += "  No diagnostic data available\n"
            }
            fullExport += "\n"
        }

        // Add current diagnostic issues if any
        if !diagnosticIssues.isEmpty {
            fullExport += "=== CURRENT DIAGNOSTIC ISSUES ===\n"
            for issue in diagnosticIssues {
                fullExport += "• \(issue.severity.rawValue): \(issue.description)\n"
                fullExport += "  Category: \(issue.category.rawValue)\n"
                fullExport += "  Impact: \(issue.impact)\n\n"
            }
        }

        // Share the export
        shareExportData(fullExport)
    }

    private func shareExportData(_ exportData: String) {
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: [exportData],
                applicationActivities: nil
            )

            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }

    func importTestCases(from jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            addLog("❌ Invalid JSON string for import")
            return
        }

        let decoder = JSONDecoder()
        do {
            let importedCases = try decoder.decode([TestCase].self, from: data)
            savedTestCases.append(contentsOf: importedCases)
            addLog("✅ Imported \(importedCases.count) test cases")
        } catch {
            addLog("❌ Failed to import test cases: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func createTestCase(endTime: Date) -> TestCase {
        guard let startTime = testCaseStartTime else {
            return TestCase(
                id: UUID(),
                name: currentTestCase,
                notes: testCaseNotes,
                startTime: Date(),
                endTime: endTime,
                logs: testCaseLogs + capturedDebugLogs,
                locations: testCaseLocations,
                tripData: getTripData(),
                deviceInfo: getDeviceInfo(),
                diagnosticData: getDiagnosticData(startTime: Date(), endTime: endTime)
            )
        }

        return TestCase(
            id: UUID(),
            name: currentTestCase,
            notes: testCaseNotes,
            startTime: startTime,
            endTime: endTime,
            logs: testCaseLogs + capturedDebugLogs,
            locations: testCaseLocations,
            tripData: getTripData(),
            deviceInfo: getDeviceInfo(),
            diagnosticData: getDiagnosticData(startTime: startTime, endTime: endTime)
        )
    }

    private func getDeviceInfo() -> TestCase.DeviceInfo {
        let device = UIDevice.current
        let bundle = Bundle.main

        return TestCase.DeviceInfo(
            model: device.model,
            systemVersion: device.systemVersion,
            appVersion: bundle
                .infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func addLog(_ message: String) {
        print("🧪 [TestCaseManager] \(message)")
    }

    // MARK: - Diagnostic Data Integration

    private func getDiagnosticData(startTime: Date, endTime: Date) -> DiagnosticData? {
        guard let diagnosticManager = diagnosticManager else {
            addLog("⚠️ No diagnostic manager available")
            return nil
        }

        return diagnosticManager.getDiagnosticDataForTimeRange(from: startTime, to: endTime)
    }

    private func getTripData() -> TestCase.TripData? {
        guard let locationManager = locationManager else {
            addLog("⚠️ No location manager available")
            return nil
        }

        // Always return trip data if we have start time, regardless of active status
        guard let startTime = locationManager.tripStartTime else {
            return nil
        }

        let endTime = locationManager.tripEndTime ?? Date()
        let duration = endTime.timeIntervalSince(startTime)
        let isActive = locationManager.isTripActive && locationManager.tripEndTime == nil

        return TestCase.TripData(
            isActive: isActive,
            startTime: startTime,
            endTime: locationManager.tripEndTime,
            distance: DistanceConverter.metersToMiles(locationManager.currentTripDistance),
            duration: duration
        )
    }

    // MARK: - Debug Log Capture

    private func startDebugLogCapture() {
        debugLogStartTime = Date()
        capturedDebugLogs.removeAll()

        // Start monitoring debug logs from LocationManager
        if let locationManager = locationManager {
            // Capture existing debug logs with timestamps
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss.SSS"
            let timestamp = dateFormatter.string(from: Date())

            capturedDebugLogs = locationManager.debugLogs.map { log in
                if log.hasPrefix("[") {
                    return log // Already has timestamp
                } else {
                    return "[\(timestamp)] \(log)"
                }
            }
        }

        addLog("📝 Started capturing debug logs")
    }

    private func stopDebugLogCapture() {
        guard debugLogStartTime != nil else { return }

        // Capture any new debug logs that appeared during the test
        if let locationManager = locationManager {
            let newLogs = locationManager.debugLogs.filter { _ in
                // This is a simplified approach - in a real implementation,
                // you'd want to timestamp each log entry
                true
            }
            capturedDebugLogs.append(contentsOf: newLogs)
        }

        addLog("📝 Stopped capturing debug logs. Total captured: \(capturedDebugLogs.count)")
        debugLogStartTime = nil
    }

    // MARK: - Test Case Analysis

    func getTestCaseSummary() -> String {
        guard !savedTestCases.isEmpty else {
            return "No test cases recorded"
        }

        var summary = "Test Case Summary:\n"
        summary += "Total test cases: \(savedTestCases.count)\n\n"

        for (index, testCase) in savedTestCases.enumerated() {
            summary += "\(index + 1). \(testCase.name)\n"
            summary += "   Duration: \(formatDuration(testCase.endTime.timeIntervalSince(testCase.startTime)))\n"
            summary += "   Locations: \(testCase.locations.count)\n"
            summary += "   Logs: \(testCase.logs.count)\n"
            if !testCase.notes.isEmpty {
                summary += "   Notes: \(testCase.notes)\n"
            }
            summary += "\n"
        }

        return summary
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
