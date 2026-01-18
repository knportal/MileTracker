import SwiftUI

struct TripHistoryListView: View {
    @ObservedObject var viewModel: TripHistoryViewModel
    let startTrackingAction: (() -> Void)?

    @State private var showingShareSheet = false
    @State private var showingClearAllAlert = false
    @State private var exportText = ""
    @State private var pendingDeleteTrip: TripRecord?

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(TripHistoryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Trips")
                    Spacer()
                    Text("\(viewModel.filteredTrips.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Total distance")
                    Spacer()
                    let miles = DistanceConverter
                        .metersToMiles(viewModel.filteredTotalDistanceMeters)
                    Text(DistanceConverter.formatDistanceInMiles(miles))
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.filteredTrips.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)

                        Text("No trips found")
                            .font(.headline)

                        Text(
                            "Start tracking to record a trip, then come back here to view and export it."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                        if let startTrackingAction {
                            Button("Start Tracking") {
                                startTrackingAction()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(viewModel.groupedSections, id: \.title) { section in
                    Section(section.title) {
                        ForEach(section.trips) { trip in
                            NavigationLink {
                                TripDetailView(viewModel: viewModel, trip: trip)
                            } label: {
                                TripRow(trip: trip)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingDeleteTrip = trip
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    exportText = viewModel.exportCSV(trip: trip)
                                    showingShareSheet = true
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                            }
                        }
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
                .disabled(viewModel.filteredTrips.isEmpty)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear All") {
                    showingClearAllAlert = true
                }
                .disabled(viewModel.filteredTrips.isEmpty)
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
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
        .alert("Delete Trip?", isPresented: Binding(
            get: { pendingDeleteTrip != nil },
            set: { newValue in
                if !newValue { pendingDeleteTrip = nil }
            }
        )) {
            Button("Delete", role: .destructive) {
                guard let trip = pendingDeleteTrip else { return }
                Task { await viewModel.deleteTrip(id: trip.id) }
                pendingDeleteTrip = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteTrip = nil
            }
        } message: {
            Text("This will permanently delete this trip from history.")
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
