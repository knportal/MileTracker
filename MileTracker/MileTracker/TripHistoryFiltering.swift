import Foundation

enum TripHistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case days7 = "7 Days"
    case days30 = "30 Days"

    var id: String { rawValue }
}

enum TripHistoryFiltering {
    struct GroupedSection: Equatable {
        let title: String
        let trips: [TripRecord]
    }

    static func filterTrips(
        _ trips: [TripRecord],
        filter: TripHistoryFilter,
        now: Date,
        calendar: Calendar
    ) -> [TripRecord] {
        switch filter {
        case .all:
            return trips
        case .today:
            return trips.filter { calendar.isDate($0.endTime, inSameDayAs: now) }
        case .days7:
            return trips.filter { isWithinDays($0.endTime, days: 7, now: now, calendar: calendar) }
        case .days30:
            return trips.filter { isWithinDays($0.endTime, days: 30, now: now, calendar: calendar) }
        }
    }

    static func groupTrips(
        _ trips: [TripRecord],
        now: Date,
        calendar: Calendar
    ) -> [GroupedSection] {
        // Trips are assumed to already be in most-recent-first order; we preserve order.
        var today: [TripRecord] = []
        var thisWeek: [TripRecord] = []
        var earlier: [TripRecord] = []

        for trip in trips {
            if calendar.isDate(trip.endTime, inSameDayAs: now) {
                today.append(trip)
            } else if isWithinDays(trip.endTime, days: 7, now: now, calendar: calendar) {
                thisWeek.append(trip)
            } else {
                earlier.append(trip)
            }
        }

        var sections: [GroupedSection] = []
        if !today.isEmpty { sections.append(GroupedSection(title: "Today", trips: today)) }
        if !thisWeek
            .isEmpty { sections.append(GroupedSection(title: "This Week", trips: thisWeek)) }
        if !earlier.isEmpty { sections.append(GroupedSection(title: "Earlier", trips: earlier)) }
        return sections
    }

    // MARK: - Private

    private static func isWithinDays(
        _ date: Date,
        days: Int,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard days > 0 else { return false }
        guard date <= now else { return false }

        guard let start = calendar.date(byAdding: .day, value: -days, to: now) else {
            return false
        }
        return date >= start
    }
}
