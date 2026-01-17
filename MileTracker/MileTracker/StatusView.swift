import SwiftUI

struct StatusView: View {
    @ObservedObject var locationManager: LocationManager

    private var permissionLevelText: String {
        switch locationManager.authorizationStatus.rawValue {
        case 0: return "Not Determined"
        case 1: return "Restricted"
        case 2: return "Denied"
        case 3: return "When In Use"
        case 4: return "Always"
        default: return "Unknown"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title and total distance
            VStack(spacing: 8) {
                Text("MileTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                let totalDistanceInMeters = DistanceConverter
                    .sanitizeDistance(locationManager.totalAccumulatedDistance)
                let totalDistanceInMiles = DistanceConverter.metersToMiles(totalDistanceInMeters)
                Text(
                    "Total Distance: \(DistanceConverter.formatDistanceInMiles(totalDistanceInMiles))"
                )
                .font(.headline)
                .foregroundColor(.secondary)
            }

            // Status indicators
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: locationManager.isTracking ? "location.fill" : "location")
                        .foregroundColor(locationManager.isTracking ? .green : .red)
                    Text(locationManager.isTracking ? "Tracking Active" : "Not Tracking")
                        .fontWeight(.medium)
                }

                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.blue)
                    Text("Permission: \(permissionLevelText)")
                        .fontWeight(.medium)
                }

                if locationManager.isTripActive {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.orange)
                        Text("Trip Active")
                            .fontWeight(.medium)
                    }

                    if let startTime = locationManager.tripStartTime {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("Started: \(formatTime(startTime))")
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
