//
//  ContentView.swift
//  MileTracker
//
//  Created by Kenneth Nygren on 8/15/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var locationManager = LocationManager()

    // Test Case Management State
    @State private var showingStartTestCaseAlert = false
    @State private var showingAddNoteAlert = false
    @State private var showingTestCaseSummary = false
    @State private var showingSavedTestCases = false
    @State private var showingClearTestCasesAlert = false
    @State private var showingDiagnosticIssues = false
    @State private var testCaseName = ""
    @State private var testCaseNotes = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status View
                StatusView(locationManager: locationManager)

                // Control Buttons
                ControlButtonsView(locationManager: locationManager)

                // Mock Mode View (Debug only)
                #if DEBUG
                    MockModeView(locationManager: locationManager)
                #endif

                // Test Case Management
                TestCaseManagementView(locationManager: locationManager)

                // Debug Logs
                DebugLogsView(locationManager: locationManager)
            }
            .padding()
        }
        .alert("Start Test Case", isPresented: $showingStartTestCaseAlert) {
            TextField("Test Case Name", text: $testCaseName)
            Button("Start") {
                locationManager.startTestCase(name: testCaseName, notes: testCaseNotes)
                testCaseName = ""
                testCaseNotes = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for this test case")
        }
        .alert("Add Note", isPresented: $showingAddNoteAlert) {
            TextField("Note", text: $testCaseNotes)
            Button("Add") {
                locationManager.addTestCaseLog("Note: \(testCaseNotes)")
                testCaseNotes = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Add a note to the current test case")
        }
        .alert("Clear All Test Cases", isPresented: $showingClearTestCasesAlert) {
            Button("Clear All", role: .destructive) {
                locationManager.clearAllTestCases()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all saved test cases. This action cannot be undone.")
        }
    }
}

// MARK: - Test Case Management View

struct TestCaseManagementView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var showingStartTestCaseAlert = false
    @State private var showingAddNoteAlert = false
    @State private var showingTestCaseSummary = false
    @State private var showingSavedTestCases = false
    @State private var showingClearTestCasesAlert = false
    @State private var testCaseName = ""
    @State private var testCaseNotes = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("🧪 Test Case Management")
                .font(.headline)
                .foregroundColor(.purple)

            HStack(spacing: 12) {
                Button(locationManager.isRecordingTestCase ? "Stop Test Case" : "Start Test Case") {
                    if locationManager.isRecordingTestCase {
                        locationManager.stopTestCase()
                    } else {
                        showingStartTestCaseAlert = true
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(locationManager.isRecordingTestCase ? .red : .green)

                Button("Add Note") {
                    showingAddNoteAlert = true
                }
                .disabled(!locationManager.isRecordingTestCase)
                .buttonStyle(.bordered)
                .foregroundColor(.blue)
            }

            HStack(spacing: 12) {
                Button("View Summary") {
                    showingTestCaseSummary = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)

                Button("Saved Cases") {
                    showingSavedTestCases = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.purple)

                Button("Export All") {
                    locationManager.exportAllTestCases()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.green)
                .disabled(locationManager.savedTestCases.isEmpty)

                Button("Clear All") {
                    showingClearTestCasesAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }

            if locationManager.isRecordingTestCase {
                VStack(spacing: 4) {
                    Text("Recording: \(locationManager.currentTestCase)")
                        .font(.caption)
                        .foregroundColor(.green)
                    if !locationManager.testCaseNotes.isEmpty {
                        Text("Notes: \(locationManager.testCaseNotes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemPurple).opacity(0.1))
        .cornerRadius(12)
        .alert("Start Test Case", isPresented: $showingStartTestCaseAlert) {
            TextField("Test Case Name", text: $testCaseName)
            Button("Start") {
                locationManager.startTestCase(name: testCaseName, notes: testCaseNotes)
                testCaseName = ""
                testCaseNotes = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for this test case")
        }
        .alert("Add Note", isPresented: $showingAddNoteAlert) {
            TextField("Note", text: $testCaseNotes)
            Button("Add") {
                locationManager.addTestCaseLog("Note: \(testCaseNotes)")
                testCaseNotes = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Add a note to the current test case")
        }
        .alert("Clear All Test Cases", isPresented: $showingClearTestCasesAlert) {
            Button("Clear All", role: .destructive) {
                locationManager.clearAllTestCases()
            }
            Button("Cancel", role: .cancel) {}
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
}

// MARK: - Debug Logs View

struct DebugLogsView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var showingExportSheet = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("📋 Debug Logs")
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    .disabled(locationManager.debugLogs.isEmpty)

                    Button("Clear") {
                        locationManager.debugLogs.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(
                        Array(locationManager.debugLogs.suffix(20).enumerated()),
                        id: \.offset
                    ) { _, log in
                        Text(log)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingExportSheet) {
            DebugLogsExportView(logs: locationManager.debugLogs)
        }
    }
}

struct DebugLogsExportView: View {
    let logs: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var exportText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Debug Logs Export")
                    .font(.headline)
                    .padding(.top)

                Text("Total Logs: \(logs.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ScrollView {
                    Text(exportText)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)

                Button("Share Logs") {
                    showingShareSheet = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(logs.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Export Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            exportText = logs.joined(separator: "\n")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [exportText])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Test Case Summary View

struct TestCaseSummaryView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(locationManager.getTestCaseSummary())
                        .font(.body)
                        .padding()
                }
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

// MARK: - Saved Test Cases View

struct SavedTestCasesView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(locationManager.savedTestCases) { testCase in
                VStack(alignment: .leading, spacing: 8) {
                    Text(testCase.name)
                        .font(.headline)
                    Text(
                        "Duration: \(formatDuration(testCase.endTime.timeIntervalSince(testCase.startTime)))"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    Text("Locations: \(testCase.locations.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !testCase.notes.isEmpty {
                        Text("Notes: \(testCase.notes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Saved Test Cases")
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

// MARK: - Diagnostic Issues View

struct DiagnosticIssuesView: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if locationManager.diagnosticIssues.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("No Issues Detected")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(
                            "Your drive diagnostics show no problems. Everything is working optimally!"
                        )
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(locationManager.diagnosticIssues) { issue in
                            DiagnosticIssueRow(issue: issue)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Diagnostic Issues")
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

struct DiagnosticIssueRow: View {
    let issue: DiagnosticIssue

    private var severityColor: Color {
        switch issue.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }

    private var severityIcon: String {
        switch issue.severity {
        case .critical: return "🚨"
        case .high: return "⚠️"
        case .medium: return "🔍"
        case .low: return "ℹ️"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(severityIcon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.description)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(issue.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(issue.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Impact:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(issue.impact)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Recommendation:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(issue.recommendation)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            if !issue.data.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Details:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(Array(issue.data.keys.sorted()), id: \.self) { key in
                        if let value = issue.data[key] {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(value)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }

            Text(formatDate(issue.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
