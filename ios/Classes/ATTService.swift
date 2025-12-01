import Foundation
import AppTrackingTransparency
import AdSupport

/// Native iOS service for App Tracking Transparency (ATT) Framework
/// Handles IDFA collection and tracking authorization requests
@available(iOS 14.0, *)
class ATTService {

    // MARK: - Singleton

    static let shared = ATTService()

    private init() {}

    // MARK: - Authorization Status

    /// Get current tracking authorization status
    /// - Returns: Status as integer (0-3)
    @available(iOS 14.0, *)
    func getTrackingAuthorizationStatus() -> Int {
        if #available(iOS 14.0, *) {
            return ATTrackingManager.trackingAuthorizationStatus.rawValue
        }
        return 3 // .authorized for pre-iOS 14
    }

    /// Get tracking authorization status as string
    @available(iOS 14.0, *)
    func getTrackingAuthorizationStatusString() -> String {
        if #available(iOS 14.0, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .notDetermined:
                return "notDetermined"
            case .restricted:
                return "restricted"
            case .denied:
                return "denied"
            case .authorized:
                return "authorized"
            @unknown default:
                return "unknown"
            }
        }
        return "authorized" // Pre-iOS 14
    }

    // MARK: - Request Authorization

    /// Request tracking authorization from user
    /// - Parameter completion: Completion handler with status
    @available(iOS 14.0, *)
    func requestTrackingAuthorization(completion: @escaping (Int) -> Void) {
        if #available(iOS 14.0, *) {
            #if DEBUG
            print("[LinkGravity] ATT: Requesting tracking authorization")
            #endif

            ATTrackingManager.requestTrackingAuthorization { status in
                #if DEBUG
                print("[LinkGravity] ATT: Authorization status - \(status.rawValue)")
                #endif
                completion(status.rawValue)
            }
        } else {
            // Pre-iOS 14 - tracking always authorized
            completion(3) // .authorized
        }
    }

    // MARK: - IDFA

    /// Get IDFA (Identifier for Advertisers) if available
    /// Returns nil if tracking not authorized or IDFA unavailable
    /// - Returns: IDFA string or nil
    func getIDFA() -> String? {
        if #available(iOS 14.0, *) {
            // Check authorization status
            guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
                #if DEBUG
                print("[LinkGravity] ATT: IDFA not available - tracking not authorized")
                #endif
                return nil
            }
        }

        // Get IDFA
        let idfa = ASIdentifierManager.shared().advertisingIdentifier

        // Check if IDFA is valid (not all zeros)
        let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
        if idfa == zeroUUID {
            #if DEBUG
            print("[LinkGravity] ATT: IDFA is zero UUID - not available")
            #endif
            return nil
        }

        let idfaString = idfa.uuidString
        #if DEBUG
        print("[LinkGravity] ATT: IDFA available - \(idfaString)")
        #endif

        return idfaString
    }

    /// Check if advertising tracking is enabled
    /// - Returns: True if tracking is enabled
    func isAdvertisingTrackingEnabled() -> Bool {
        if #available(iOS 14.0, *) {
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        } else {
            // Pre-iOS 14
            return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        }
    }

    // MARK: - Utility Methods

    /// Check if ATT framework is available on this device
    func isATTAvailable() -> Bool {
        if #available(iOS 14.0, *) {
            return true
        }
        return false
    }

    /// Get all tracking information as dictionary
    func getTrackingInfo() -> [String: Any] {
        var info: [String: Any] = [:]

        if #available(iOS 14.0, *) {
            info["attAvailable"] = true
            info["status"] = getTrackingAuthorizationStatusString()
            info["statusCode"] = getTrackingAuthorizationStatus()
        } else {
            info["attAvailable"] = false
            info["status"] = "authorized" // Pre-iOS 14
            info["statusCode"] = 3
        }

        info["trackingEnabled"] = isAdvertisingTrackingEnabled()
        info["idfa"] = getIDFA() ?? NSNull()

        return info
    }
}

// MARK: - ATTrackingManager Extension

@available(iOS 14.0, *)
extension ATTrackingManager.AuthorizationStatus {
    /// Convert to human-readable string
    var stringValue: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}
