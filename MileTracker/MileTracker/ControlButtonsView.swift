import SwiftUI

struct ControlButtonsView: View {
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 16) {
            // Main control buttons
            HStack(spacing: 20) {
                Button(locationManager.isTracking ? "Stop Tracking" : "Start Tracking") {
                    if locationManager.isTracking {
                        locationManager.stopTracking()
                    } else {
                        locationManager.startTracking()
                    }
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(locationManager.isTracking ? .red : .green)

                Button("Request Permission") {
                    locationManager.requestLocationPermission()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.blue)
            }

            // Trip control buttons
            HStack(spacing: 20) {
                Button("Start Trip") {
                    locationManager.startTrip()
                }
                .disabled(locationManager.isTripActive)
                .buttonStyle(.bordered)
                .foregroundColor(.orange)

                Button("Stop Trip") {
                    locationManager.stopTrip()
                }
                .disabled(!locationManager.isTripActive)
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }

            // Diagnostic mode toggle
            HStack {
                Image(systemName: locationManager.diagnosticMode ? "stethoscope" : "stethoscope")
                    .foregroundColor(locationManager.diagnosticMode ? .purple : .secondary)
                Text("Diagnostic Mode")
                    .fontWeight(.medium)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { locationManager.diagnosticMode },
                    set: { locationManager.diagnosticMode = $0 }
                ))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
