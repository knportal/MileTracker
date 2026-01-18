import Combine
import Foundation

@MainActor
final class TripHistoryViewModel: ObservableObject {
    @Published private(set) var trips: [TripRecord] = []
    @Published var errorMessage: String?

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

    func delete(atOffsets offsets: IndexSet) async {
        var updated = trips
        updated.remove(atOffsets: offsets)
        do {
            try await store.save(updated.sorted { $0.endTime < $1.endTime })
            NotificationCenter.default.post(name: .tripHistoryDidChange, object: nil)
        } catch {
            errorMessage = "Failed to delete trip(s): \(error.localizedDescription)"
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

    func exportAllCSV() -> String {
        formatter.csvAll(trips: trips.sorted { $0.endTime > $1.endTime })
    }

    func exportCSV(trip: TripRecord) -> String {
        formatter.csv(trip: trip)
    }

    func exportText(trip: TripRecord) -> String {
        formatter.textSummary(trip: trip)
    }
}
