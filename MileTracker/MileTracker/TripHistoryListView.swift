import SwiftUI

struct TripHistoryListView: View {
    @ObservedObject var viewModel: TripHistoryViewModel

    @State private var showingShareSheet = false
    @State private var showingClearAllAlert = false
    @State private var exportText = ""

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Trips")
                    Spacer()
                    Text("\(viewModel.trips.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Total distance")
                    Spacer()
                    let miles = DistanceConverter.metersToMiles(viewModel.totalDistanceMeters)
                    Text(DistanceConverter.formatDistanceInMiles(miles))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if viewModel.trips.isEmpty {
                    Text("No trips yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.trips) { trip in
                        NavigationLink {
                            TripDetailView(viewModel: viewModel, trip: trip)
                        } label: {
                            TripRow(trip: trip)
                        }
                    }
                    .onDelete { offsets in
                        Task { await viewModel.delete(atOffsets: offsets) }
                    }
                }
            }
        }
        .navigationTitle("Trip History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Export All") {
                    exportText = viewModel.exportAllCSV()
                    showingShareSheet = true
                }
                .disabled(viewModel.trips.isEmpty)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear All") {
                    showingClearAllAlert = true
                }
                .disabled(viewModel.trips.isEmpty)
            }
        }
        .task {
            await viewModel.load()
        }
        .alert("Trip History Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue { viewModel.errorMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .alert("Clear All Trips?", isPresented: $showingClearAllAlert) {
            Button("Clear All", role: .destructive) {
                Task { await viewModel.deleteAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all trip history. This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [exportText])
        }
    }
}

private struct TripRow: View {
    let trip: TripRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trip.endTime, style: .date)
                    .font(.headline)
                Spacer()
                let miles = DistanceConverter.metersToMiles(trip.distanceMeters)
                Text(DistanceConverter.formatDistanceInMiles(miles))
                    .font(.headline)
            }

            HStack(spacing: 8) {
                Text(trip.startTime, style: .time)
                Text("–")
                Text(trip.endTime, style: .time)

                Spacer()

                Text(formatDuration(trip.duration))
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if trip.isMock {
                Text("Mock trip")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
