//
//  ContentView.swift
//  MileTracker
//
//  Created by Kenneth Nygren on 8/15/25.
//

import SwiftUI

#if DEBUG
struct MockModeView: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🧪 Mock Mode Controls")
                .font(.headline)
                .foregroundColor(.purple)
            
            HStack(spacing: 20) {
                Button(locationManager.isMockMode ? "Disable Mock" : "Enable Mock") {
                    locationManager.toggleMockMode()
                }
                .buttonStyle(.bordered)
                .foregroundColor(locationManager.isMockMode ? .red : .purple)
                
                Button("Next Trip") {
                    locationManager.nextMockTrip()
                }
                .disabled(!locationManager.isMockMode)
                .buttonStyle(.bordered)
                .foregroundColor(.blue)
            }
            
            if locationManager.isMockMode {
                VStack(spacing: 4) {
                    Text("Trip \(locationManager.mockTripIndex + 1) of \(locationManager.getMockTripCount())")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text(locationManager.getCurrentMockTripInfo())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Manual mock location button for testing
                    Button("Add Mock Location") {
                        locationManager.addMockLocation()
                    }
                    .disabled(!locationManager.isTracking)
                    .buttonStyle(.bordered)
                    .foregroundColor(.green)
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemPurple).opacity(0.1))
        .cornerRadius(12)
    }
}
#endif

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    
    // Test Case Management State
    @State private var showingStartTestCaseAlert = false
    @State private var showingAddNoteAlert = false
    @State private var showingTestCaseSummary = false
    @State private var showingSavedTestCases = false
    @State private var showingClearTestCasesAlert = false
    @State private var testCaseName = ""
    @State private var testCaseNotes = ""
    
    private var permissionLevelText: String {
        switch locationManager.authorizationStatus.rawValue {
        case 0: return "Not Determined"
        case 1: return "Restricted"
        case 2: return "Denied"
        case 3: return "When In Use"
        case 4: return "Always"
        default: return "Unknown"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title and total distance
                VStack(spacing: 8) {
                    Text("MileTracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Total Distance: \(String(format: "%.2f", locationManager.calculateTotalDistance())) miles")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                // Trip Status Section
                VStack(spacing: 12) {
                    Text("Trip Status")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    if locationManager.isTripActive {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.green)
                                Text("Trip Active")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                            
                            if let startTime = locationManager.tripStartTime {
                                Text("Started: \(formatTime(startTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Current Distance: \(String(format: "%.2f", locationManager.currentTripDistance)) miles")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        HStack {
                            Image(systemName: "car")
                                .foregroundColor(.secondary)
                            Text("No Active Trip")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // Trip Control Buttons
                VStack(spacing: 12) {
                    Text("Trip Controls")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 20) {
                        Button(locationManager.isTripActive ? "Stop Trip" : "Start Trip") {
                            if locationManager.isTripActive {
                                locationManager.stopTripManually()
                            } else {
                                locationManager.startTripManually()
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(locationManager.isTripActive ? .red : .green)
                        
                        Button("Reset Trip") {
                            locationManager.resetTripData()
                        }
                        .disabled(!locationManager.isTripActive)
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                    }
                }
                
                // Location Status
                if let error = locationManager.locationError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Authorization Status Display
                switch locationManager.authorizationStatus.rawValue {
                case 0: // .notDetermined
                    Button("Enable Location Tracking") {
                        locationManager.requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    
                case 3: // .authorizedWhenInUse
                    VStack(spacing: 8) {
                        Text("Location: When In Use")
                            .foregroundColor(.orange)
                        Button("Enable Background Tracking") {
                            locationManager.requestLocationPermission()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                case 4: // .authorizedAlways
                    Text("Location: Always Allowed ✅")
                        .foregroundColor(.green)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(8)
                    
                case 1, 2: // .restricted, .denied
                    VStack(spacing: 8) {
                        Text("Location Access Denied")
                            .foregroundColor(.red)
                        Button("Open Settings") {
                            locationManager.openSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                default:
                    Text("Unknown Authorization Status")
                        .foregroundColor(.secondary)
                }
                
                // Tracking Controls
                HStack(spacing: 20) {
                    Button("Start Tracking") {
                        locationManager.startLocationUpdates()
                    }
                    .disabled(locationManager.authorizationStatus.rawValue < 3 || locationManager.isTracking)
                    .buttonStyle(.borderedProminent)
                    
                    Button("Stop Tracking") {
                        locationManager.stopLocationUpdates()
                    }
                    .disabled(!locationManager.isTracking)
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Button("Reset Distance") {
                        locationManager.resetDistance()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                }
                
                HStack(spacing: 20) {
                    Button("Force Stop") {
                        locationManager.forceStopLocationUpdates()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    
                    Button("Start Location") {
                        locationManager.startLocationUpdates()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.green)
                    
                    Button("Reset State") {
                        locationManager.resetTrackingState()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.purple)
                    
                    Button("Restart Motion") {
                        locationManager.restartMotionDetection()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.orange)
                    
                    Button("Debug State") {
                        locationManager.logCurrentState()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.gray)
                    
                    Button("Health Check") {
                        locationManager.checkSystemHealth()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.purple)
                    
                    Button("Refresh Status") {
                        locationManager.refreshAuthorizationStatus()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.blue)
                }
                
                #if DEBUG
                // Mock Mode Testing Controls
                VStack(spacing: 12) {
                    Text("Mock Mode Testing")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    HStack(spacing: 20) {
                        Button("Simulate 🚗") {
                            locationManager.simulateAutomotiveActivity()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.green)
                        
                        Button("Simulate 🚶") {
                            locationManager.simulateNonAutomotiveActivity()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                    }
                }
                #endif
                
                // Test Case Management Section
                VStack(spacing: 12) {
                    Text("🧪 Test Case Management")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    // Current Test Case Status
                    VStack(spacing: 8) {
                        HStack {
                            Text("Current Test:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(locationManager.currentTestCase)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(locationManager.isRecordingTestCase ? .green : .secondary)
                        }
                        
                        if locationManager.isRecordingTestCase {
                            HStack {
                                Text("Recording:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("🟢 ACTIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if !locationManager.testCaseNotes.isEmpty {
                            HStack {
                                Text("Notes:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(locationManager.testCaseNotes)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemOrange).opacity(0.1))
                    .cornerRadius(8)
                    
                    // Test Case Controls
                    VStack(spacing: 8) {
                        // Start/End Test Case
                        HStack(spacing: 12) {
                            Button(locationManager.isRecordingTestCase ? "End Test Case" : "Start Test Case") {
                                if locationManager.isRecordingTestCase {
                                    locationManager.endTestCase()
                                } else {
                                    // Show alert to input test case name and notes
                                    showStartTestCaseAlert()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .foregroundColor(locationManager.isRecordingTestCase ? .red : .orange)
                            
                            if locationManager.isRecordingTestCase {
                                Button("Add Note") {
                                    showAddNoteAlert()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Test Case Management
                        HStack(spacing: 12) {
                            Button("Test Summary") {
                                showTestCaseSummary()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.green)
                            
                            Button("Export All") {
                                exportAllTestCases()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.purple)
                            
                            Button("Clear All") {
                                showClearTestCasesAlert()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                    
                    // Saved Test Cases Count
                    if !locationManager.savedTestCases.isEmpty {
                        HStack {
                            Text("📁 Saved Test Cases: \(locationManager.savedTestCases.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("View All") {
                                showSavedTestCases()
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(.systemOrange).opacity(0.1))
                .cornerRadius(12)
                
                // Debug Info
                VStack(spacing: 8) {
                    Text("Status: \(locationManager.authorizationStatus.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Permission Level: \(permissionLevelText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Background Available: \(locationManager.checkBackgroundLocationAvailability() ? "YES" : "NO")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Tracking Active: \(locationManager.isTracking ? "YES" : "NO")")
                        .font(.caption)
                        .foregroundColor(locationManager.isTracking ? .green : .red)
                    
                    Text("Speed Detection: \(locationManager.getSpeedDetectionStatus())")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Location Tracking: \(locationManager.getLocationTrackingStatus())")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Trip Active: \(locationManager.isTripActive ? "YES" : "NO")")
                        .font(.caption)
                        .foregroundColor(locationManager.isTripActive ? .green : .red)
                    
                    if locationManager.isTripActive {
                        Text("Trip Distance: \(String(format: "%.2f", locationManager.currentTripDistance)) miles")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    #if DEBUG
                    Text("Mock Mode: \(locationManager.isMockMode ? "ON" : "OFF")")
                        .font(.caption)
                        .foregroundColor(locationManager.isMockMode ? .purple : .secondary)
                    #endif
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                #if DEBUG
                MockModeView(locationManager: locationManager)
                #endif
                
                // Debug Logs
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Debug Logs")
                            .font(.headline)
                        Spacer()
                        Button("Clear") {
                            locationManager.clearDebugLogs()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        Button("Export") {
                            locationManager.exportDebugReport()
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(locationManager.debugLogs, id: \.self) { log in
                                Text(log)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            print("ContentView: onAppear called")
            locationManager.initializeAuthorizationStatus()
        }
        .alert("Start Test Case", isPresented: $showingStartTestCaseAlert) {
            TextField("Test Case Name", text: $testCaseName)
            TextField("Notes (Optional)", text: $testCaseNotes)
            Button("Start") {
                locationManager.startTestCase(name: testCaseName, notes: testCaseNotes)
                testCaseName = ""
                testCaseNotes = ""
            }
            Button("Cancel", role: .cancel) {
                testCaseName = ""
                testCaseNotes = ""
            }
        } message: {
            Text("Enter a name and optional notes for this test case.")
        }
        .alert("Add Note", isPresented: $showingAddNoteAlert) {
            TextField("Additional Notes", text: $testCaseNotes)
            Button("Add") {
                locationManager.testCaseNotes += (locationManager.testCaseNotes.isEmpty ? "" : "\n") + testCaseNotes
                testCaseNotes = ""
            }
            Button("Cancel", role: .cancel) {
                testCaseNotes = ""
            }
        } message: {
            Text("Add additional notes to the current test case.")
        }
        .alert("Clear All Test Cases", isPresented: $showingClearTestCasesAlert) {
            Button("Clear All", role: .destructive) {
                locationManager.clearAllTestCases()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all saved test cases. This action cannot be undone.")
        }
        .sheet(isPresented: $showingTestCaseSummary) {
            TestCaseSummaryView(locationManager: locationManager)
        }
        .sheet(isPresented: $showingSavedTestCases) {
            SavedTestCasesView(locationManager: locationManager)
        }
    }
    
    // MARK: - Test Case Management Methods
    
    private func showStartTestCaseAlert() {
        testCaseName = ""
        testCaseNotes = ""
        showingStartTestCaseAlert = true
    }
    
    private func showAddNoteAlert() {
        testCaseNotes = ""
        showingAddNoteAlert = true
    }
    
    private func showTestCaseSummary() {
        showingTestCaseSummary = true
    }
    
    private func showSavedTestCases() {
        showingSavedTestCases = true
    }
    
    private func showClearTestCasesAlert() {
        showingClearTestCasesAlert = true
    }
    
    private func exportAllTestCases() {
        let report = locationManager.exportAllTestCases()
        let activityVC = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Test Case Management Views

struct TestCaseSummaryView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text(locationManager.getTestCaseSummary())
                    .font(.body)
                    .multilineTextAlignment(.leading)
        .padding()
                
                Spacer()
            }
            .navigationTitle("Test Case Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SavedTestCasesView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(locationManager.savedTestCases) { testCase in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(testCase.name)
                                .font(.headline)
                            Spacer()
                            Text(formatDate(testCase.startTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !testCase.notes.isEmpty {
                            Text(testCase.notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("📍 \(testCase.locations.count) GPS points")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            if let tripData = testCase.tripData {
                                Text("🚗 \(String(format: "%.2f", tripData.distance)) miles")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Button("Export") {
                                exportTestCase(testCase)
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Saved Test Cases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export All") {
                        exportAllTestCases()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func exportTestCase(_ testCase: LocationManager.TestCase) {
        let report = locationManager.exportTestCase(testCase)
        let activityVC = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func exportAllTestCases() {
        let report = locationManager.exportAllTestCases()
        let activityVC = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

#Preview {
    ContentView()
}
