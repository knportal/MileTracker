import Foundation

struct TripRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    /// Stored in meters to avoid locale assumptions; UI can derive miles as needed.
    let distanceMeters: Double
    let isMock: Bool
    let notes: String?

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        distanceMeters: Double,
        isMock: Bool,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distanceMeters = distanceMeters
        self.isMock = isMock
        self.notes = notes
    }

    var duration: TimeInterval {
        max(0, endTime.timeIntervalSince(startTime))
    }
}
