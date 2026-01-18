import Combine
import Foundation

final class TripHistoryRecorder {
    private let tripDetection: TripDetection
    private let store: any TripHistoryStoring
    private let isMockProvider: @Sendable () -> Bool
    private let onError: (@Sendable (Error) -> Void)?

    private var cancellables: Set<AnyCancellable> = []
    private var lastRecordedEndTime: Date?

    init(
        tripDetection: TripDetection,
        store: any TripHistoryStoring,
        isMockProvider: @escaping @Sendable () -> Bool,
        onError: (@Sendable (Error) -> Void)? = nil
    ) {
        self.tripDetection = tripDetection
        self.store = store
        self.isMockProvider = isMockProvider
        self.onError = onError

        // Record when a trip end time is set (covers manual stop, stopTracking, and auto-stop
        // timer).
        tripDetection.$tripEndTime
            .compactMap { $0 }
            .sink { [weak self] endTime in
                self?.handleTripEnded(endTime: endTime)
            }
            .store(in: &cancellables)
    }

    private func handleTripEnded(endTime: Date) {
        guard tripDetection.isTripActive == false else { return }
        guard let startTime = tripDetection.tripStartTime else { return }

        // Prevent duplicates if multiple observers/actions cause repeated end-time publishes.
        if lastRecordedEndTime == endTime {
            return
        }
        lastRecordedEndTime = endTime

        let distanceMeters = tripDetection.currentTripDistance.isFinite
            ? max(0, tripDetection.currentTripDistance)
            : 0

        let record = TripRecord(
            startTime: startTime,
            endTime: endTime,
            distanceMeters: distanceMeters,
            isMock: isMockProvider(),
            notes: nil
        )

        Task {
            do {
                try await store.append(record)
                NotificationCenter.default.post(name: .tripHistoryDidChange, object: nil)
            } catch {
                onError?(error)
            }
        }
    }
}
