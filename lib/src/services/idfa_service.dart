import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// Tracking authorization status for iOS App Tracking Transparency (ATT)
enum TrackingAuthorizationStatus {
  /// User has not yet been asked for tracking permission
  notDetermined,

  /// Tracking authorization restricted (e.g., parental controls)
  restricted,

  /// User explicitly denied tracking permission
  denied,

  /// User granted tracking permission
  authorized,
}

/// Service for handling Apple's App Tracking Transparency (ATT) Framework
/// Manages IDFA collection and tracking authorization requests
/// Requires iOS 14.0+ for ATT framework
///
/// **Privacy Note:**
/// IDFA collection is completely optional. By default, LinkGravity SDK
/// uses privacy-first probabilistic attribution without IDFA.
/// Only use this service if you need deterministic attribution and
/// have obtained proper user consent.
class IDFAService {
  static const MethodChannel _channel =
      MethodChannel('linkgravity_flutter_sdk');

  /// Request tracking authorization from user
  /// Shows the iOS system prompt asking for permission
  ///
  /// **Important:**
  /// - Only available on iOS 14.0+
  /// - You must add `NSUserTrackingUsageDescription` to Info.plist
  /// - Can only be called once per app installation
  /// - Should be called at an appropriate moment when user understands the value
  ///
  /// Returns the authorization status after user responds
  ///
  /// Example:
  /// ```dart
  /// final status = await idfaService.requestTrackingAuthorization();
  /// if (status == TrackingAuthorizationStatus.authorized) {
  ///   print('User granted tracking permission');
  /// }
  /// ```
  Future<TrackingAuthorizationStatus> requestTrackingAuthorization() async {
    if (!Platform.isIOS) {
      LinkGravityLogger.debug('ATT: Not available on non-iOS platform');
      return TrackingAuthorizationStatus.notDetermined;
    }

    try {
      LinkGravityLogger.debug('ATT: Requesting tracking authorization');

      final statusCode =
          await _channel.invokeMethod<int>('att_requestAuthorization');

      final status = _statusFromCode(statusCode ?? 0);

      LinkGravityLogger.debug('ATT: Authorization status - ${status.name}');

      return status;
    } catch (e) {
      LinkGravityLogger.error('ATT: Error requesting authorization', e);
      return TrackingAuthorizationStatus.notDetermined;
    }
  }

  /// Get current tracking authorization status without requesting
  /// Use this to check status before deciding whether to request permission
  ///
  /// Example:
  /// ```dart
  /// final status = await idfaService.getTrackingAuthorizationStatus();
  /// if (status == TrackingAuthorizationStatus.notDetermined) {
  ///   // User hasn't been asked yet - good time to request
  ///   await idfaService.requestTrackingAuthorization();
  /// }
  /// ```
  Future<TrackingAuthorizationStatus> getTrackingAuthorizationStatus() async {
    if (!Platform.isIOS) {
      LinkGravityLogger.debug('ATT: Not available on non-iOS platform');
      return TrackingAuthorizationStatus.notDetermined;
    }

    try {
      final statusCode =
          await _channel.invokeMethod<int>('att_getAuthorizationStatus');

      return _statusFromCode(statusCode ?? 0);
    } catch (e) {
      LinkGravityLogger.error('ATT: Error getting authorization status', e);
      return TrackingAuthorizationStatus.notDetermined;
    }
  }

  /// Get IDFA (Identifier for Advertisers) if available
  /// Returns null if:
  /// - Not on iOS
  /// - User denied tracking permission
  /// - IDFA is unavailable (e.g., all zeros UUID)
  ///
  /// Example:
  /// ```dart
  /// final idfa = await idfaService.getIDFA();
  /// if (idfa != null) {
  ///   print('IDFA: $idfa');
  ///   // Use for deterministic attribution
  /// } else {
  ///   print('IDFA not available - using fingerprinting');
  /// }
  /// ```
  Future<String?> getIDFA() async {
    if (!Platform.isIOS) {
      LinkGravityLogger.debug('ATT: IDFA not available on non-iOS platform');
      return null;
    }

    try {
      final idfa = await _channel.invokeMethod<String>('att_getIDFA');

      if (idfa != null && idfa.isNotEmpty) {
        LinkGravityLogger.debug('ATT: IDFA available');
        // Don't log actual IDFA for privacy
        return idfa;
      } else {
        LinkGravityLogger.debug(
            'ATT: IDFA not available (tracking not authorized or IDFA is zero UUID)');
        return null;
      }
    } catch (e) {
      LinkGravityLogger.error('ATT: Error getting IDFA', e);
      return null;
    }
  }

  /// Check if ATT framework is available on this device
  /// Returns true on iOS 14.0+, false otherwise
  Future<bool> isATTAvailable() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final available = await _channel.invokeMethod<bool>('att_isAvailable');
      return available ?? false;
    } catch (e) {
      LinkGravityLogger.error('ATT: Error checking availability', e);
      return false;
    }
  }

  /// Get comprehensive tracking information for debugging
  /// Returns a map with all ATT-related information
  ///
  /// Example response:
  /// ```dart
  /// {
  ///   'attAvailable': true,
  ///   'status': 'authorized',
  ///   'statusCode': 3,
  ///   'trackingEnabled': true,
  ///   'idfa': 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' or null
  /// }
  /// ```
  Future<Map<String, dynamic>> getTrackingInfo() async {
    if (!Platform.isIOS) {
      return {
        'attAvailable': false,
        'status': 'notDetermined',
        'statusCode': 0,
        'trackingEnabled': false,
        'idfa': null,
      };
    }

    try {
      final info = await _channel.invokeMethod<Map>('att_getTrackingInfo');

      if (info != null) {
        return Map<String, dynamic>.from(info);
      } else {
        return {
          'attAvailable': false,
          'status': 'notDetermined',
          'statusCode': 0,
          'trackingEnabled': false,
          'idfa': null,
        };
      }
    } catch (e) {
      LinkGravityLogger.error('ATT: Error getting tracking info', e);
      return {
        'attAvailable': false,
        'status': 'error',
        'statusCode': -1,
        'trackingEnabled': false,
        'idfa': null,
        'error': e.toString(),
      };
    }
  }

  /// Convert iOS status code to enum
  TrackingAuthorizationStatus _statusFromCode(int code) {
    switch (code) {
      case 0:
        return TrackingAuthorizationStatus.notDetermined;
      case 1:
        return TrackingAuthorizationStatus.restricted;
      case 2:
        return TrackingAuthorizationStatus.denied;
      case 3:
        return TrackingAuthorizationStatus.authorized;
      default:
        return TrackingAuthorizationStatus.notDetermined;
    }
  }
}
