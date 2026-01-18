import Foundation
@testable import MileTracker
import Testing

struct TripHistoryFilteringTests {
    private func makeCalendarUTC() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func dateUTC(_ iso8601: String) -> Date {
        // Example: "2026-01-18T12:00:00Z"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: iso8601) ?? Date(timeIntervalSince1970: 0)
    }

    private func trip(end: Date) -> TripRecord {
        TripRecord(
            startTime: end.addingTimeInterval(-60),
            endTime: end,
            distanceMeters: 0,
            isMock: false,
            notes: nil
        )
    }

    @Test func filterTodayIncludesOnlySameDay() async throws {
        let calendar = makeCalendarUTC()
        let now = dateUTC("2026-01-18T12:00:00Z")

        let todayTrip = trip(end: dateUTC("2026-01-18T08:00:00Z"))
        let yesterdayTrip = trip(end: dateUTC("2026-01-17T23:00:00Z"))

        let filtered = TripHistoryFiltering.filterTrips(
            [todayTrip, yesterdayTrip],
            filter: .today,
            now: now,
            calendar: calendar
        )

        #expect(filtered == [todayTrip])
    }

    @Test func filter7DaysIncludesBoundaryAndExcludesOlder() async throws {
        let calendar = makeCalendarUTC()
        let now = dateUTC("2026-01-18T12:00:00Z")

        let within = trip(end: dateUTC("2026-01-12T12:00:00Z")) // 6 days ago
        let boundary = trip(end: dateUTC("2026-01-11T12:00:00Z")) // 7 days ago
        let older = trip(end: dateUTC("2026-01-10T12:00:00Z")) // 8 days ago

        let filtered = TripHistoryFiltering.filterTrips(
            [within, boundary, older],
            filter: .days7,
            now: now,
            calendar: calendar
        )

        #expect(filtered.contains(within))
        #expect(filtered.contains(boundary))
        #expect(filtered.contains(older) == false)
    }

    @Test func filter30DaysExcludesFutureTrips() async throws {
        let calendar = makeCalendarUTC()
        let now = dateUTC("2026-01-18T12:00:00Z")

        let future = trip(end: dateUTC("2026-01-19T12:00:00Z"))
        let filtered = TripHistoryFiltering.filterTrips(
            [future],
            filter: .days30,
            now: now,
            calendar: calendar
        )

        #expect(filtered.isEmpty)
    }

    @Test func groupTripsCreatesTodayThisWeekEarlier() async throws {
        let calendar = makeCalendarUTC()
        let now = dateUTC("2026-01-18T12:00:00Z")

        let t1 = trip(end: dateUTC("2026-01-18T11:00:00Z")) // today
        let t2 = trip(end: dateUTC("2026-01-15T12:00:00Z")) // this week (last 7 days)
        let t3 = trip(end: dateUTC("2025-12-01T12:00:00Z")) // earlier

        let grouped = TripHistoryFiltering.groupTrips([t1, t2, t3], now: now, calendar: calendar)

        #expect(grouped.count == 3)
        #expect(grouped[0].title == "Today")
        #expect(grouped[0].trips == [t1])
        #expect(grouped[1].title == "This Week")
        #expect(grouped[1].trips == [t2])
        #expect(grouped[2].title == "Earlier")
        #expect(grouped[2].trips == [t3])
    }
}
