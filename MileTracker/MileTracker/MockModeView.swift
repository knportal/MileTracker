import SwiftUI

#if DEBUG
    struct MockModeView: View {
        @ObservedObject var locationManager: LocationManager

        var body: some View {
            VStack(spacing: 12) {
                Text("🧪 Mock Mode Controls")
                    .font(.headline)
                    .foregroundColor(.purple)

                HStack(spacing: 20) {
                    Button(locationManager.isMockMode ? "Disable Mock" : "Enable Mock") {
                        locationManager.toggleMockMode()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(locationManager.isMockMode ? .red : .purple)

                    Button("Next Trip") {
                        locationManager.nextMockTrip()
                    }
                    .disabled(!locationManager.isMockMode)
                    .buttonStyle(.bordered)
                    .foregroundColor(.blue)
                }

                if locationManager.isMockMode {
                    VStack(spacing: 4) {
                        Text(
                            "Trip \(locationManager.mockTripIndex + 1) of \(locationManager.getMockTripCount())"
                        )
                        .font(.caption)
                        .foregroundColor(.purple)
                        Text(locationManager.getCurrentMockTripInfo())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        // Manual mock location button for testing
                        Button("Add Mock Location") {
                            locationManager.addMockLocation()
                        }
                        .disabled(!locationManager.isTracking)
                        .buttonStyle(.bordered)
                        .foregroundColor(.green)
                        .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color(.systemPurple).opacity(0.1))
            .cornerRadius(12)
        }
    }
#endif
