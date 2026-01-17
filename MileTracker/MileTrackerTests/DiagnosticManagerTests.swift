import CoreLocation
@testable import MileTracker
import Testing

@Suite("DiagnosticManager Tests")
struct DiagnosticManagerTests {
    // MARK: - Test Setup/Teardown

    private func createCleanDiagnosticManager() -> DiagnosticManager {
        let diagnosticManager = DiagnosticManager()
        // Ensure clean state
        diagnosticManager.stopDiagnosticMode()
        return diagnosticManager
    }

    @Test func initialState() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        #expect(diagnosticManager.diagnosticMode == false)
        #expect(diagnosticManager.diagnosticIssues.isEmpty)
    }

    @Test func testStartDiagnosticMode() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        diagnosticManager.startDiagnosticMode()
        #expect(diagnosticManager.diagnosticMode == true)
    }

    @Test func testStopDiagnosticMode() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        diagnosticManager.startDiagnosticMode()
        #expect(diagnosticManager.diagnosticMode == true)

        diagnosticManager.stopDiagnosticMode()
        #expect(diagnosticManager.diagnosticMode == false)
    }

    @Test func testAddDiagnosticIssue() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        let issue = DiagnosticIssue(
            severity: .medium,
            category: .gps,
            description: "Test issue",
            impact: "Test impact",
            recommendation: "Test recommendation"
        )
        diagnosticManager.addDiagnosticIssue(issue)
        #expect(diagnosticManager.diagnosticIssues.count == 1)
        #expect(diagnosticManager.diagnosticIssues.first?.description == "Test issue")
    }

    @Test func multipleDiagnosticIssues() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        let issue1 = DiagnosticIssue(
            severity: .medium,
            category: .gps,
            description: "First issue",
            impact: "First impact",
            recommendation: "First recommendation"
        )
        let issue2 = DiagnosticIssue(
            severity: .high,
            category: .battery,
            description: "Second issue",
            impact: "Second impact",
            recommendation: "Second recommendation"
        )

        diagnosticManager.addDiagnosticIssue(issue1)
        diagnosticManager.addDiagnosticIssue(issue2)

        #expect(diagnosticManager.diagnosticIssues.count == 2)
    }

    @Test func diagnosticIssueProperties() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        let issue = DiagnosticIssue(
            severity: .medium,
            category: .gps,
            description: "Test issue",
            impact: "Test impact",
            recommendation: "Test recommendation"
        )
        diagnosticManager.addDiagnosticIssue(issue)

        #expect(diagnosticManager.diagnosticIssues.first?.category == .gps)
        #expect(diagnosticManager.diagnosticIssues.first?.severity == .medium)
    }

    @Test func testUpdateAuthorizationStatus() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        diagnosticManager.updateAuthorizationStatus(.authorizedWhenInUse)
        // Test that the method doesn't crash and can be called
        #expect(true) // Basic test that the method executes
    }

    @Test func testEmergencyMemoryCleanup() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        // Test that emergency cleanup can be called
        diagnosticManager.emergencyMemoryCleanup()
        #expect(true) // Basic test that the method executes
    }

    @Test func testGetDiagnosticData() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        let data = diagnosticManager.getDiagnosticData()

        // Test that we get some diagnostic data
        #expect(data.issues.isEmpty) // Should be empty initially
        #expect(data.systemStateSnapshots.isEmpty) // Should be empty initially
    }

    @Test func testGetDiagnosticDataForTimeRange() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        let startTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let endTime = Date()

        let data = diagnosticManager.getDiagnosticDataForTimeRange(from: startTime, to: endTime)

        // Test that we get some diagnostic data for the time range
        #expect(data.issues.isEmpty) // Should be empty initially
        #expect(data.systemStateSnapshots.isEmpty) // Should be empty initially
    }

    @Test func diagnosticModeToggle() async throws {
        let diagnosticManager = createCleanDiagnosticManager()

        // Start diagnostic mode
        diagnosticManager.startDiagnosticMode()
        #expect(diagnosticManager.diagnosticMode == true)

        // Stop diagnostic mode
        diagnosticManager.stopDiagnosticMode()
        #expect(diagnosticManager.diagnosticMode == false)
    }

    @Test func diagnosticIssueWithData() async throws {
        let diagnosticManager = createCleanDiagnosticManager()
        let customData = ["key1": "value1", "key2": "value2"]
        let issue = DiagnosticIssue(
            severity: .high,
            category: .performance,
            description: "Performance issue",
            impact: "App may be slow",
            recommendation: "Check memory usage",
            data: customData
        )

        diagnosticManager.addDiagnosticIssue(issue)
        #expect(diagnosticManager.diagnosticIssues.count == 1)
        #expect(diagnosticManager.diagnosticIssues.first?.data["key1"] == "value1")
    }

    @Test func diagnosticIssueSeverityLevels() async throws {
        let diagnosticManager = createCleanDiagnosticManager()

        let lowIssue = DiagnosticIssue(
            severity: .low,
            category: .dataQuality,
            description: "Minor issue",
            impact: "Minimal impact",
            recommendation: "Monitor"
        )

        let criticalIssue = DiagnosticIssue(
            severity: .critical,
            category: .system,
            description: "Critical issue",
            impact: "App may crash",
            recommendation: "Fix immediately"
        )

        diagnosticManager.addDiagnosticIssue(lowIssue)
        diagnosticManager.addDiagnosticIssue(criticalIssue)

        #expect(diagnosticManager.diagnosticIssues.count == 2)
        #expect(diagnosticManager.diagnosticIssues.contains { $0.severity == .low })
        #expect(diagnosticManager.diagnosticIssues.contains { $0.severity == .critical })
    }

    @Test func diagnosticIssueCategories() async throws {
        let diagnosticManager = createCleanDiagnosticManager()

        let gpsIssue = DiagnosticIssue(
            severity: .medium,
            category: .gps,
            description: "GPS issue",
            impact: "Location tracking affected",
            recommendation: "Check GPS signal"
        )

        let batteryIssue = DiagnosticIssue(
            severity: .high,
            category: .battery,
            description: "Battery issue",
            impact: "High battery drain",
            recommendation: "Optimize location services"
        )

        diagnosticManager.addDiagnosticIssue(gpsIssue)
        diagnosticManager.addDiagnosticIssue(batteryIssue)

        #expect(diagnosticManager.diagnosticIssues.count == 2)
        #expect(diagnosticManager.diagnosticIssues.contains { $0.category == .gps })
        #expect(diagnosticManager.diagnosticIssues.contains { $0.category == .battery })
    }
}
