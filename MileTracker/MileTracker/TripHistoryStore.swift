import Foundation

protocol TripHistoryStoring: Sendable {
    func load() async throws -> [TripRecord]
    func save(_ trips: [TripRecord]) async throws
    func append(_ trip: TripRecord) async throws
    func deleteAll() async throws
    func fileURL() async -> URL
}

actor FileTripHistoryStore: TripHistoryStoring {
    struct TripHistoryFile: Codable, Sendable {
        let version: Int
        var trips: [TripRecord]
    }

    private enum Constants {
        static let currentVersion = 1
        static let filename = "trip_history.json"
    }

    private let url: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseDirectoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        let directoryURL: URL
        if let baseDirectoryURL {
            directoryURL = baseDirectoryURL
        } else if let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first {
            directoryURL = documents
        } else {
            // Fallback: use temporary directory if Documents is unavailable (shouldn't happen on iOS).
            directoryURL = fileManager.temporaryDirectory
        }

        self.url = directoryURL.appendingPathComponent(Constants.filename, isDirectory: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        self.decoder = decoder
    }

    func fileURL() async -> URL {
        url
    }

    func load() async throws -> [TripRecord] {
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        let file = try decoder.decode(TripHistoryFile.self, from: data)
        return file.trips
    }

    func save(_ trips: [TripRecord]) async throws {
        try ensureParentDirectoryExists()
        let file = TripHistoryFile(version: Constants.currentVersion, trips: trips)
        let data = try encoder.encode(file)
        try data.write(to: url, options: [.atomic])
    }

    func append(_ trip: TripRecord) async throws {
        var trips = try await load()
        trips.append(trip)
        try await save(trips)
    }

    func deleteAll() async throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func ensureParentDirectoryExists() throws {
        let parent = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parent.path) {
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        }
    }
}
