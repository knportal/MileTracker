import Foundation
@testable import MileTracker
import Testing

struct TripExportFormatterTests {
    private func makeTrip(
        distanceMeters: Double = 1609.344,
        isMock: Bool = false,
        notes: String? = nil
    ) -> TripRecord {
        TripRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 60),
            distanceMeters: distanceMeters,
            isMock: isMock,
            notes: notes
        )
    }

    @Test func csvIncludesHeaderAndOneRow() async throws {
        let formatter = TripExportFormatter()
        let csv = formatter.csv(trip: makeTrip())
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 2)
        #expect(lines.first?.contains("id,startTime,endTime") == true)
    }

    @Test func csvEscapesNotesWithCommaQuoteAndNewline() async throws {
        let formatter = TripExportFormatter()
        let notes = "hello, \"world\"\nnext"
        let csv = formatter.csv(trip: makeTrip(notes: notes))
        // Notes column should be quoted and internal quotes doubled.
        #expect(csv.contains("\"hello, \"\"world\"\"\nnext\""))
    }

    @Test func csvAllHasRowCountHeaderPlusTrips() async throws {
        let formatter = TripExportFormatter()
        let csv = formatter.csvAll(trips: [makeTrip(), makeTrip(notes: "two")])
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.count == 3)
    }

    @Test func textSummaryContainsDistanceAndMockFlag() async throws {
        let formatter = TripExportFormatter()
        let summary = formatter.textSummary(trip: makeTrip())
        #expect(summary.contains("Distance:"))
        #expect(summary.contains("Mock: No"))
    }

    @Test func textSummaryAllIncludesTotalsAndTripCount() async throws {
        let formatter = TripExportFormatter()
        let text = formatter.textSummaryAll(trips: [
            makeTrip(),
            makeTrip(distanceMeters: 0, isMock: true)
        ])
        #expect(text.contains("Total trips: 2"))
        #expect(text.contains("Total distance:"))
    }
}
