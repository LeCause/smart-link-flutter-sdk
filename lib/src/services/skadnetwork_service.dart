import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/logger.dart';
import 'api_service.dart';

/// Service for handling Apple's SKAdNetwork
/// Manages conversion value updates and postback tracking
/// Requires iOS 14.0+ for basic features, iOS 15.4+ for advanced features
class SKAdNetworkService {
  final ApiService apiService;

  static const MethodChannel _channel =
      MethodChannel('linkgravity_flutter_sdk');

  SKAdNetworkService({required this.apiService});

  /// Update conversion value (iOS 14.0+)
  /// [conversionValue] must be between 0-63 (6-bit value)
  ///
  /// Example:
  /// ```dart
  /// await skadService.updateConversionValue(10); // User completed tutorial
  /// ```
  Future<bool> updateConversionValue(int conversionValue) async {
    if (!Platform.isIOS) {
      LinkGravityLogger.debug(
          'SKAdNetwork: Not available on non-iOS platform');
      return false;
    }

    if (conversionValue < 0 || conversionValue > 63) {
      LinkGravityLogger.warning(
          'SKAdNetwork: Invalid conversion value $conversionValue. Must be 0-63');
      return false;
    }

    try {
      LinkGravityLogger.debug(
          'SKAdNetwork: Updating conversion value to $conversionValue');

      final result = await _channel.invokeMethod<bool>(
        'skad_updateConversionValue',
        {'conversionValue': conversionValue},
      );

      if (result == true) {
        LinkGravityLogger.debug(
            'SKAdNetwork: Conversion value updated successfully');
        return true;
      } else {
        LinkGravityLogger.warning(
            'SKAdNetwork: Conversion value update failed');
        return false;
      }
    } catch (e) {
      LinkGravityLogger.error('SKAdNetwork: Error updating conversion value',
          e);
      return false;
    }
  }

  /// Update postback conversion value with coarse value (iOS 15.4+)
  /// Provides more granular conversion tracking
  ///
  /// [fineValue]: 6-bit fine-grained value (0-63)
  /// [coarseValue]: Coarse conversion value ('low', 'medium', 'high')
  /// [lockWindow]: Whether to lock the conversion window
  ///
  /// Example:
  /// ```dart
  /// await skadService.updatePostbackConversionValue(
  ///   fineValue: 42,
  ///   coarseValue: 'high',
  ///   lockWindow: false,
  /// );
  /// ```
  Future<bool> updatePostbackConversionValue({
    required int fineValue,
    required String coarseValue,
    bool lockWindow = false,
  }) async {
    if (!Platform.isIOS) {
      LinkGravityLogger.debug(
          'SKAdNetwork: Not available on non-iOS platform');
      return false;
    }

    if (fineValue < 0 || fineValue > 63) {
      LinkGravityLogger.warning(
          'SKAdNetwork: Invalid fine value $fineValue. Must be 0-63');
      return false;
    }

    final validCoarseValues = ['low', 'medium', 'high'];
    if (!validCoarseValues.contains(coarseValue.toLowerCase())) {
      LinkGravityLogger.warning(
          'SKAdNetwork: Invalid coarse value "$coarseValue". Must be low, medium, or high');
      return false;
    }

    try {
      LinkGravityLogger.debug(
          'SKAdNetwork: Updating postback (fine: $fineValue, coarse: $coarseValue, lock: $lockWindow)');

      final result = await _channel.invokeMethod<bool>(
        'skad_updatePostbackConversionValue',
        {
          'fineValue': fineValue,
          'coarseValue': coarseValue.toLowerCase(),
          'lockWindow': lockWindow,
        },
      );

      if (result == true) {
        LinkGravityLogger.debug(
            'SKAdNetwork: Postback conversion value updated successfully');
        return true;
      } else {
        LinkGravityLogger.warning(
            'SKAdNetwork: Postback conversion value update failed');
        return false;
      }
    } on PlatformException catch (e) {
      if (e.code == 'UNAVAILABLE') {
        LinkGravityLogger.warning(
            'SKAdNetwork: Postback conversion requires iOS 15.4+');
      } else {
        LinkGravityLogger.error(
            'SKAdNetwork: Error updating postback conversion value', e);
      }
      return false;
    } catch (e) {
      LinkGravityLogger.error(
          'SKAdNetwork: Error updating postback conversion value', e);
      return false;
    }
  }

  /// Get SKAdNetwork version available on this device
  /// Returns version string like "4.0", "3.0", "2.2", "2.0", or "Not supported"
  Future<String> getSKAdNetworkVersion() async {
    if (!Platform.isIOS) {
      return 'Not supported';
    }

    try {
      final version =
          await _channel.invokeMethod<String>('skad_getSKAdNetworkVersion');
      return version ?? 'Not supported';
    } catch (e) {
      LinkGravityLogger.error('SKAdNetwork: Error getting version', e);
      return 'Not supported';
    }
  }

  /// Check if SKAdNetwork is available on this device
  /// Returns true on iOS 14.0+, false otherwise
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final available =
          await _channel.invokeMethod<bool>('skad_isAvailable');
      return available ?? false;
    } catch (e) {
      LinkGravityLogger.error('SKAdNetwork: Error checking availability', e);
      return false;
    }
  }

  /// Get SKAdNetwork configuration for debugging
  Future<Map<String, dynamic>> getConfig() async {
    final version = await getSKAdNetworkVersion();
    final available = await isAvailable();

    return {
      'platform': Platform.isIOS ? 'ios' : 'other',
      'skAdNetworkVersion': version,
      'available': available,
      'supportsPostback': version == '3.0' || version == '4.0',
      'supportsCoarseValue': version == '4.0',
    };
  }

  /// Legacy method - kept for backward compatibility
  /// On iOS 14.0+, SKAdNetwork automatically handles registration
  @Deprecated('SKAdNetwork automatically handles registration on iOS 14.0+')
  Future<void> requestPostback() async {
    LinkGravityLogger.debug(
        'SKAdNetwork: requestPostback() is deprecated. Registration is automatic on iOS 14.0+');
  }

  /// Legacy method with callback - kept for backward compatibility
  @Deprecated('Use updateConversionValue() instead')
  Future<bool> requestPostbackWithCallback({
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      onSuccess?.call();
      return true;
    } catch (e) {
      final errorMessage = 'SKAdNetwork postback request failed: $e';
      LinkGravityLogger.error(errorMessage, e);
      onError?.call(errorMessage);
      return false;
    }
  }
}
