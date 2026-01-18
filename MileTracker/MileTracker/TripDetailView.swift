import SwiftUI

struct TripDetailView: View {
    @ObservedObject var viewModel: TripHistoryViewModel
    let trip: TripRecord

    @State private var showingShareSheet = false
    @State private var exportText = ""

    var body: some View {
        List {
            Section("Summary") {
                row("Start", value: formattedDateTime(trip.startTime))
                row("End", value: formattedDateTime(trip.endTime))
                row("Duration", value: formatDuration(trip.duration))

                let miles = DistanceConverter.metersToMiles(trip.distanceMeters)
                row("Distance", value: DistanceConverter.formatDistanceInMiles(miles))

                row("Mock", value: trip.isMock ? "Yes" : "No")
            }

            if let notes = trip.notes,
               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            Section {
                Button("Share CSV") {
                    exportText = viewModel.exportCSV(trip: trip)
                    showingShareSheet = true
                }

                Button("Share Summary") {
                    exportText = viewModel.exportText(trip: trip)
                    showingShareSheet = true
                }
            }
        }
        .navigationTitle("Trip")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [exportText])
        }
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds / 60) % 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
