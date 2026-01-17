import Foundation

/// Utility class for converting and formatting distance measurements
class DistanceConverter {
    // MARK: - Constants

    /// Meters per mile (exact conversion factor)
    private static let metersPerMile: Double = 1609.344

    // MARK: - Conversion Methods

    /// Convert meters to miles
    /// - Parameter meters: Distance in meters
    /// - Returns: Distance in miles
    static func metersToMiles(_ meters: Double) -> Double {
        guard meters.isFinite && meters >= 0 else {
            return 0.0
        }
        return meters / metersPerMile
    }

    /// Convert miles to meters
    /// - Parameter miles: Distance in miles
    /// - Returns: Distance in meters
    static func milesToMeters(_ miles: Double) -> Double {
        guard miles.isFinite && miles >= 0 else {
            return 0.0
        }
        return miles * metersPerMile
    }

    /// Convert meters to kilometers
    /// - Parameter meters: Distance in meters
    /// - Returns: Distance in kilometers
    static func metersToKilometers(_ meters: Double) -> Double {
        guard meters.isFinite && meters >= 0 else {
            return 0.0
        }
        return meters / 1000.0
    }

    /// Convert kilometers to meters
    /// - Parameter kilometers: Distance in kilometers
    /// - Returns: Distance in meters
    static func kilometersToMeters(_ kilometers: Double) -> Double {
        guard kilometers.isFinite && kilometers >= 0 else {
            return 0.0
        }
        return kilometers * 1000.0
    }

    // MARK: - Formatting Methods

    /// Format distance in miles with appropriate precision
    /// - Parameter miles: Distance in miles
    /// - Returns: Formatted string (e.g., "0.25 mi", "1.5 mi", "12.34 mi")
    static func formatDistanceInMiles(_ miles: Double) -> String {
        guard miles.isFinite && miles >= 0 else {
            return "0.00 mi"
        }

        if miles < 0.01 {
            return "0.00 mi"
        } else if miles < 1.0 {
            return String(format: "%.2f mi", miles)
        } else if miles < 10.0 {
            return String(format: "%.2f mi", miles)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }

    /// Format distance in meters with appropriate precision
    /// - Parameter meters: Distance in meters
    /// - Returns: Formatted string (e.g., "25 m", "1.2 km", "12.3 km")
    static func formatDistanceInMeters(_ meters: Double) -> String {
        guard meters.isFinite && meters >= 0 else {
            return "0 m"
        }

        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            let kilometers = metersToKilometers(meters)
            if kilometers < 10 {
                return String(format: "%.1f km", kilometers)
            } else {
                return String(format: "%.0f km", kilometers)
            }
        }
    }

    /// Format distance with automatic unit selection (miles for US, km for others)
    /// - Parameter meters: Distance in meters
    /// - Returns: Formatted string in appropriate units
    static func formatDistance(_ meters: Double) -> String {
        // For now, default to miles (US format)
        // In a real app, you'd check the user's locale
        let miles = metersToMiles(meters)
        return formatDistanceInMiles(miles)
    }

    // MARK: - Validation Methods

    /// Check if a distance value is valid
    /// - Parameter distance: Distance value to validate
    /// - Returns: True if the distance is valid (finite and non-negative)
    static func isValidDistance(_ distance: Double) -> Bool {
        return distance.isFinite && distance >= 0
    }

    /// Sanitize a distance value (convert invalid values to 0)
    /// - Parameter distance: Distance value to sanitize
    /// - Returns: Sanitized distance value
    static func sanitizeDistance(_ distance: Double) -> Double {
        return isValidDistance(distance) ? distance : 0.0
    }

    // MARK: - Location Manager Configuration

    /// Get the recommended distance filter for CLLocationManager
    /// This provides a good balance between accuracy and battery life
    /// - Returns: Distance in meters (approximately 0.01 miles or ~16 meters)
    static func getLocationDistanceFilter() -> Double {
        return 16.0 // ~0.01 miles, good balance for trip detection
    }

    // MARK: - Debug Methods

    /// Get detailed distance information for debugging
    /// - Parameter meters: Distance in meters
    /// - Returns: Detailed string with all conversions
    static func debugDistanceInfo(_ meters: Double) -> String {
        let miles = metersToMiles(meters)
        let kilometers = metersToKilometers(meters)

        return """
        Distance Debug Info:
        - Raw meters: \(String(format: "%.3f", meters))
        - Miles: \(String(format: "%.6f", miles))
        - Kilometers: \(String(format: "%.3f", kilometers))
        - Formatted miles: \(formatDistanceInMiles(miles))
        - Formatted meters: \(formatDistanceInMeters(meters))
        - Is valid: \(isValidDistance(meters))
        """
    }
}
