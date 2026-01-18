import Foundation
@testable import MileTracker
import Testing

struct TripHistoryStoreTests {
    private func makeTempDirectory() throws -> URL {
        let base = FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent(
            "TripHistoryStoreTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeTrip(
        start: Date = Date(timeIntervalSince1970: 0),
        end: Date = Date(timeIntervalSince1970: 60),
        distanceMeters: Double = 1609.344,
        isMock: Bool = false,
        notes: String? = nil
    ) -> TripRecord {
        TripRecord(
            startTime: start,
            endTime: end,
            distanceMeters: distanceMeters,
            isMock: isMock,
            notes: notes
        )
    }

    @Test func loadMissingFileReturnsEmpty() async throws {
        let dir = try makeTempDirectory()
        let store = FileTripHistoryStore(baseDirectoryURL: dir)
        let trips = try await store.load()
        #expect(trips.isEmpty)
    }

    @Test func saveThenLoadRoundTrip() async throws {
        let dir = try makeTempDirectory()
        let store = FileTripHistoryStore(baseDirectoryURL: dir)

        let trip1 = makeTrip(notes: "First")
        let trip2 = makeTrip(
            start: Date(timeIntervalSince1970: 100),
            end: Date(timeIntervalSince1970: 160),
            distanceMeters: 0,
            isMock: true,
            notes: "Second"
        )

        try await store.save([trip1, trip2])
        let loaded = try await store.load()
        #expect(loaded == [trip1, trip2])
    }

    @Test func appendAddsToExistingTrips() async throws {
        let dir = try makeTempDirectory()
        let store = FileTripHistoryStore(baseDirectoryURL: dir)

        let trip1 = makeTrip(notes: "A")
        let trip2 = makeTrip(
            start: Date(timeIntervalSince1970: 10),
            end: Date(timeIntervalSince1970: 20),
            notes: "B"
        )

        try await store.save([trip1])
        try await store.append(trip2)

        let loaded = try await store.load()
        #expect(loaded == [trip1, trip2])
    }

    @Test func deleteAllRemovesFileAndTrips() async throws {
        let dir = try makeTempDirectory()
        let store = FileTripHistoryStore(baseDirectoryURL: dir)

        try await store.save([makeTrip()])
        try await store.deleteAll()

        let loaded = try await store.load()
        #expect(loaded.isEmpty)
    }

    @Test func fileURLPointsAtTripHistoryJSON() async throws {
        let dir = try makeTempDirectory()
        let store = FileTripHistoryStore(baseDirectoryURL: dir)
        let url = await store.fileURL()
        #expect(url.lastPathComponent == "trip_history.json")
        #expect(url.deletingLastPathComponent() == dir)
    }
}
