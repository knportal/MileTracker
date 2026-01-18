import Combine
import Foundation

@MainActor
final class TripHistoryViewModel: ObservableObject {
    @Published private(set) var trips: [TripRecord] = []
    @Published var errorMessage: String?
    @Published var selectedFilter: TripHistoryFilter = .all

    private let store: any TripHistoryStoring
    private let formatter: TripExportFormatter
    private var cancellables: Set<AnyCancellable> = []

    init(
        store: any TripHistoryStoring,
        formatter: TripExportFormatter = TripExportFormatter()
    ) {
        self.store = store
        self.formatter = formatter

        NotificationCenter.default.publisher(for: .tripHistoryDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.load() }
            }
            .store(in: &cancellables)
    }

    func load() async {
        do {
            let loaded = try await store.load()
            trips = loaded.sorted { $0.endTime > $1.endTime }
        } catch {
            errorMessage = "Failed to load trip history: \(error.localizedDescription)"
        }
    }

    func deleteTrip(id: UUID) async {
        var updated = trips
        updated.removeAll { $0.id == id }
        do {
            // Persist in ascending order (stable file representation); UI sorts descending after
            // load.
            try await store.save(updated.sorted { $0.endTime < $1.endTime })
            NotificationCenter.default.post(name: .tripHistoryDidChange, object: nil)
        } catch {
            errorMessage = "Failed to delete trip: \(error.localizedDescription)"
        }
    }

    func deleteAll() async {
        do {
            try await store.deleteAll()
            trips = []
            NotificationCenter.default.post(name: .tripHistoryDidChange, object: nil)
        } catch {
            errorMessage = "Failed to delete all trips: \(error.localizedDescription)"
        }
    }

    var totalDistanceMeters: Double {
        trips.reduce(0.0) { $0 + $1.distanceMeters }
    }

    var filteredTotalDistanceMeters: Double {
        filteredTrips.reduce(0.0) { $0 + $1.distanceMeters }
    }

    var filteredTrips: [TripRecord] {
        let now = Date()
        let calendar = Calendar.current
        return TripHistoryFiltering.filterTrips(
            trips,
            filter: selectedFilter,
            now: now,
            calendar: calendar
        )
        .sorted { $0.endTime > $1.endTime }
    }

    var groupedSections: [TripHistoryFiltering.GroupedSection] {
        let now = Date()
        let calendar = Calendar.current
        return TripHistoryFiltering.groupTrips(filteredTrips, now: now, calendar: calendar)
    }

    func exportAllCSV() -> String {
        formatter.csvAll(trips: filteredTrips)
    }

    func exportCSV(trip: TripRecord) -> String {
        formatter.csv(trip: trip)
    }

    func exportText(trip: TripRecord) -> String {
        formatter.textSummary(trip: trip)
    }
}
