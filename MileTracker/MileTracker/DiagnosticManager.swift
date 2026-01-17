import CoreLocation
import CoreMotion
import Foundation
import UIKit

class DiagnosticManager: ObservableObject {
    // MARK: - Published Properties

    @Published var diagnosticMode: Bool = false
    @Published var diagnosticIssues: [DiagnosticIssue] = []

    // MARK: - Private Properties

    private var diagnosticStartTime: Date?
    private var locationProcessingTimes: [TimeInterval] = []
    private var memorySnapshots: [MemorySnapshot] = []
    private var batterySnapshots: [BatterySnapshot] = []
    private var gpsQualitySnapshots: [GPSQualitySnapshot] = []
    private var systemStateSnapshots: [SystemStateSnapshot] = []

    // Authorization status (updated by LocationManager)
    private var currentAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    // Memory management
    private let maxDiagnosticSnapshots = 60 // Keep last 20 minutes of data
    private let maxLocationHistory = 1000 // Keep last 1000 locations
    private let maxProcessingTimes = 100 // Keep last 100 processing time measurements

    // Timers
    private var diagnosticSystemStateTimer: Timer?
    private var diagnosticMemoryBatteryTimer: Timer?

    // MARK: - Public Methods

    func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        currentAuthorizationStatus = status
    }

    func startDiagnosticMode() {
        diagnosticMode = true
        diagnosticStartTime = Date()
        addLog("🔍 Diagnostic mode started")

        // Start monitoring timers
        startSystemStateMonitoring()
        startMemoryBatteryMonitoring()
    }

    func stopDiagnosticMode() {
        diagnosticMode = false
        diagnosticStartTime = nil

        // Stop timers
        diagnosticSystemStateTimer?.invalidate()
        diagnosticMemoryBatteryTimer?.invalidate()

        addLog("🔍 Diagnostic mode stopped")
    }

    func addLocationProcessingTime(_ time: TimeInterval) {
        locationProcessingTimes.append(time)
        manageArraySize(&locationProcessingTimes, maxSize: maxProcessingTimes)
    }

    func addGPSQualitySnapshot(_ location: CLLocation) {
        let snapshot = GPSQualitySnapshot(
            timestamp: Date(),
            accuracy: location.horizontalAccuracy,
            speed: location.speed,
            altitude: location.altitude,
            course: location.course,
            signalStrength: nil // Would need additional API to get signal strength
        )

        gpsQualitySnapshots.append(snapshot)
        manageArraySize(&gpsQualitySnapshots, maxSize: maxDiagnosticSnapshots)
    }

    func addDiagnosticIssue(_ issue: DiagnosticIssue) {
        diagnosticIssues.append(issue)
        addLog("⚠️ Diagnostic Issue: \(issue.description)")
    }

    // MARK: - Private Methods

    private func startSystemStateMonitoring() {
        diagnosticSystemStateTimer = Timer
            .scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
                self?
                    .captureSystemState(authorizationStatus: self?
                        .currentAuthorizationStatus ?? .notDetermined
                    )
            }
    }

    private func startMemoryBatteryMonitoring() {
        diagnosticMemoryBatteryTimer = Timer
            .scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
                self?.captureMemoryAndBattery()
            }
    }

    private func captureSystemState(authorizationStatus: CLAuthorizationStatus) {
        let snapshot = SystemStateSnapshot(
            timestamp: Date(),
            authorizationStatus: Int(authorizationStatus.rawValue),
            backgroundLocationAvailable: CLLocationManager.locationServicesEnabled(),
            motionDetectionActive: false, // Would need to track this from LocationManager
            lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            backgroundAppRefresh: UIApplication.shared.backgroundRefreshStatus == .available
        )

        systemStateSnapshots.append(snapshot)
        manageArraySize(&systemStateSnapshots, maxSize: maxDiagnosticSnapshots)
    }

    private func captureMemoryAndBattery() {
        // Memory snapshot
        let memorySnapshot = MemorySnapshot(
            timestamp: Date(),
            memoryUsage: getMemoryUsage(),
            availableMemory: getAvailableMemory()
        )
        memorySnapshots.append(memorySnapshot)
        manageArraySize(&memorySnapshots, maxSize: maxDiagnosticSnapshots)

        // Battery snapshot
        let batterySnapshot = BatterySnapshot(
            timestamp: Date(),
            batteryLevel: UIDevice.current.batteryLevel,
            isCharging: UIDevice.current.batteryState == .charging,
            powerMode: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Low Power" : "Normal"
        )
        batterySnapshots.append(batterySnapshot)
        manageArraySize(&batterySnapshots, maxSize: maxDiagnosticSnapshots)
    }

    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    private func getAvailableMemory() -> Int64 {
        var pagesize: vm_size_t = 0
        var pageCount: mach_port_t = 0
        var vmStats = vm_statistics64_data_t()

        host_page_size(mach_host_self(), &pagesize)

        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / 4)
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            // Calculate available memory: free + inactive + wire
            let availablePages = vmStats.free_count + vmStats.inactive_count + vmStats.wire_count
            return Int64(pagesize) * Int64(availablePages)
        }

        // Fallback: return a reasonable estimate
        return 1024 * 1024 * 1024 // 1GB estimate
    }

    private func manageArraySize<T>(_ array: inout [T], maxSize: Int) {
        if array.count > maxSize {
            let excess = array.count - maxSize
            array.removeFirst(excess)
        }
    }

    private func addLog(_ message: String) {
        print("🔍 [Diagnostic] \(message)")
    }

    // MARK: - Emergency Cleanup

    func emergencyMemoryCleanup() {
        addLog("🚨 EMERGENCY MEMORY CLEANUP: Memory usage dangerously high")

        // Force cleanup of all diagnostic arrays
        diagnosticIssues.removeAll()
        memorySnapshots.removeAll()
        batterySnapshots.removeAll()
        gpsQualitySnapshots.removeAll()
        systemStateSnapshots.removeAll()
        locationProcessingTimes.removeAll()

        addLog("🚨 Emergency cleanup completed - arrays cleared")
    }

    // MARK: - Diagnostic Data Export

    func getDiagnosticData() -> DiagnosticData {
        return DiagnosticData(
            issues: diagnosticIssues,
            memorySnapshots: memorySnapshots,
            batterySnapshots: batterySnapshots,
            gpsQualitySnapshots: gpsQualitySnapshots,
            systemStateSnapshots: systemStateSnapshots
        )
    }

    func getDiagnosticDataForTimeRange(from startTime: Date, to endTime: Date) -> DiagnosticData {
        let filteredIssues = diagnosticIssues.filter { issue in
            issue.timestamp >= startTime && issue.timestamp <= endTime
        }

        let filteredMemorySnapshots = memorySnapshots.filter { snapshot in
            snapshot.timestamp >= startTime && snapshot.timestamp <= endTime
        }

        let filteredBatterySnapshots = batterySnapshots.filter { snapshot in
            snapshot.timestamp >= startTime && snapshot.timestamp <= endTime
        }

        let filteredGPSSnapshots = gpsQualitySnapshots.filter { snapshot in
            snapshot.timestamp >= startTime && snapshot.timestamp <= endTime
        }

        let filteredSystemSnapshots = systemStateSnapshots.filter { snapshot in
            snapshot.timestamp >= startTime && snapshot.timestamp <= endTime
        }

        return DiagnosticData(
            issues: filteredIssues,
            memorySnapshots: filteredMemorySnapshots,
            batterySnapshots: filteredBatterySnapshots,
            gpsQualitySnapshots: filteredGPSSnapshots,
            systemStateSnapshots: filteredSystemSnapshots
        )
    }
}
