import Foundation
@testable import MileTracker
import Testing

private actor InMemoryTripHistoryStore: TripHistoryStoring {
    private var trips: [TripRecord] = []
    private let url: URL

    init(fileURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("in-memory-trip-history.json")
    ) {
        self.url = fileURL
    }

    func load() async throws -> [TripRecord] {
        trips
    }

    func save(_ trips: [TripRecord]) async throws {
        self.trips = trips
    }

    func append(_ trip: TripRecord) async throws {
        trips.append(trip)
    }

    func deleteAll() async throws {
        trips = []
    }

    func fileURL() async -> URL {
        url
    }
}

struct TripHistoryViewModelTests {
    private func trip(end: TimeInterval, meters: Double) -> TripRecord {
        TripRecord(
            id: UUID(),
            startTime: Date(timeIntervalSince1970: end - 60),
            endTime: Date(timeIntervalSince1970: end),
            distanceMeters: meters,
            isMock: false,
            notes: nil
        )
    }

    @Test func loadSortsMostRecentFirst() async throws {
        let store = InMemoryTripHistoryStore()
        try await store.save([trip(end: 200, meters: 1), trip(end: 100, meters: 1)])

        let viewModel = await MainActor.run { TripHistoryViewModel(store: store) }
        await viewModel.load()

        await MainActor.run {
            #expect(viewModel.trips.count == 2)
            #expect(viewModel.trips[0].endTime.timeIntervalSince1970 == 200)
            #expect(viewModel.trips[1].endTime.timeIntervalSince1970 == 100)
        }
    }

    @Test func totalDistanceMetersSumsTrips() async throws {
        let store = InMemoryTripHistoryStore()
        try await store.save([trip(end: 100, meters: 10), trip(end: 200, meters: 25)])

        let viewModel = await MainActor.run { TripHistoryViewModel(store: store) }
        await viewModel.load()

        await MainActor.run {
            #expect(viewModel.totalDistanceMeters == 35)
        }
    }
}
