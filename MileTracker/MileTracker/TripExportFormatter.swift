import Foundation

struct TripExportFormatter {
    private enum Constants {
        static let csvHeader =
            "id,startTime,endTime,durationSeconds,distanceMeters,distanceMiles,isMock,notes"
    }

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    func csv(trip: TripRecord) -> String {
        Constants.csvHeader + "\n" + csvRow(trip: trip)
    }

    func csvAll(trips: [TripRecord]) -> String {
        let rows = trips.map { csvRow(trip: $0) }
        return ([Constants.csvHeader] + rows).joined(separator: "\n")
    }

    func textSummary(trip: TripRecord) -> String {
        let start = Self.iso8601.string(from: trip.startTime)
        let end = Self.iso8601.string(from: trip.endTime)
        let miles = DistanceConverter.metersToMiles(trip.distanceMeters)

        var lines: [String] = []
        lines.append("Trip Summary")
        lines.append("ID: \(trip.id.uuidString)")
        lines.append("Start: \(start)")
        lines.append("End: \(end)")
        lines.append("Duration (seconds): \(Int(trip.duration.rounded()))")
        lines.append("Distance: \(DistanceConverter.formatDistanceInMiles(miles))")
        lines.append("Mock: \(trip.isMock ? "Yes" : "No")")
        if let notes = trip.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Notes: \(notes)")
        }
        return lines.joined(separator: "\n")
    }

    func textSummaryAll(trips: [TripRecord]) -> String {
        var lines: [String] = []
        lines.append("Trip History Summary")
        lines.append("Total trips: \(trips.count)")
        let totalMeters = trips.reduce(0.0) { $0 + $1.distanceMeters }
        let totalMiles = DistanceConverter.metersToMiles(totalMeters)
        lines.append("Total distance: \(DistanceConverter.formatDistanceInMiles(totalMiles))")
        lines.append("")

        for (index, trip) in trips.enumerated() {
            lines.append("=== Trip \(index + 1) ===")
            lines.append(textSummary(trip: trip))
            lines.append("")
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private

    private func csvRow(trip: TripRecord) -> String {
        let id = trip.id.uuidString
        let start = Self.iso8601.string(from: trip.startTime)
        let end = Self.iso8601.string(from: trip.endTime)
        let duration = Int(trip.duration.rounded())
        let meters = trip.distanceMeters
        let miles = DistanceConverter.metersToMiles(meters)
        let isMock = trip.isMock ? "true" : "false"
        let notes = trip.notes ?? ""

        return [
            csvField(id),
            csvField(start),
            csvField(end),
            String(duration),
            String(format: "%.3f", meters),
            String(format: "%.6f", miles),
            isMock,
            csvField(notes)
        ].joined(separator: ",")
    }

    private func csvField(_ value: String) -> String {
        // RFC4180-ish: quote if needed; escape quotes by doubling.
        let needsQuoting = value.contains(",") || value.contains("\"") || value
            .contains("\n") || value.contains("\r")
        if !needsQuoting {
            return value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
