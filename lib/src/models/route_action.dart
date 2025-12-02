import 'dart:async';
import 'package:flutter/material.dart';
import 'deep_link_data.dart';
import '../utils/logger.dart';

/// Action to perform when a deep link route is matched
///
/// This class wraps a navigation handler that receives both the BuildContext
/// and DeepLinkData when a deep link is matched.
///
/// The handler is automatically wrapped in [scheduleMicrotask] to prevent
/// navigation-during-build errors.
///
/// Example usage:
/// ```dart
/// // FlutterFlow with go_router
/// RouteAction((context, deepLink) {
///   context.goNamed(
///     'ProductPage',
///     extra: {'id': deepLink.getParam('id')},
///   );
/// })
///
/// // Standard Flutter Navigator
/// RouteAction((context, deepLink) {
///   Navigator.of(context).pushNamed(
///     '/product',
///     arguments: deepLink.params,
///   );
/// })
///
/// // Custom logic
/// RouteAction((context, deepLink) {
///   final productId = deepLink.getParam('id');
///   if (productId != null) {
///     context.goNamed('ProductDetails', extra: {'id': productId});
///   } else {
///     context.goNamed('HomePage');
///   }
/// })
/// ```
class RouteAction {
  /// Navigation handler that receives BuildContext and DeepLinkData
  final void Function(BuildContext context, DeepLinkData deepLink) handler;

  /// Create a route action with a navigation handler
  ///
  /// The [handler] function will be called when a deep link route is matched.
  /// It receives:
  /// - [context]: The BuildContext for navigation (always valid and mounted)
  /// - [deepLink]: The DeepLinkData containing route info, params, and metadata
  ///
  /// Example:
  /// ```dart
  /// RouteAction((ctx, data) {
  ///   ctx.goNamed('ProductPage', extra: data.params);
  /// })
  /// ```
  const RouteAction(this.handler);

  /// Execute the navigation action
  ///
  /// This method is called internally by the SDK when a route is matched.
  /// It uses [scheduleMicrotask] to avoid navigation-during-build errors.
  ///
  /// Parameters:
  /// - [context]: The BuildContext for navigation
  /// - [deepLink]: The matched deep link data
  ///
  /// You typically don't need to call this directly - the SDK handles it
  /// when you register routes with [LinkGravityClient.registerRoutes].
  void execute(BuildContext context, DeepLinkData deepLink) {
    LinkGravityLogger.debug('🔍 RouteAction.execute() - Scheduling microtask for navigation');
    scheduleMicrotask(() {
      LinkGravityLogger.debug('🔍 Microtask executing - calling navigation handler');
      try {
        handler(context, deepLink);
        LinkGravityLogger.info('✅ Navigation handler completed successfully');
      } catch (e, stackTrace) {
        LinkGravityLogger.error('❌ Route handler failed', e, stackTrace);
        rethrow;
      }
    });
    LinkGravityLogger.debug('🔍 Microtask scheduled (will execute after current frame)');
  }

  @override
  String toString() {
    return 'RouteAction(handler: $handler)';
  }
}
