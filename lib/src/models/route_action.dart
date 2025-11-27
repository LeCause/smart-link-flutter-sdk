import 'dart:async';
import 'package:flutter/material.dart';

/// Action to perform when a deep link route is matched
///
/// Supports FlutterFlow navigation patterns including goNamed and custom handlers.
///
/// Example:
/// ```dart
/// // Simple navigation
/// RouteAction.goNamed('ProductPage', extra: {'id': '123'})
///
/// // Custom handler with conditional logic
/// RouteAction.custom((context) {
///   if (condition) {
///     context.pushNamed('PageA');
///   } else {
///     context.goNamed('PageB');
///   }
/// })
/// ```
class RouteAction {
  final RouteActionType _type;
  final String? _routeName;
  final Map<String, dynamic>? _extra;
  final Map<String, String>? _pathParameters;
  final Map<String, dynamic>? _queryParameters;
  final bool _ignoreRedirect;
  final Function(BuildContext)? _customHandler;

  const RouteAction._({
    required RouteActionType type,
    String? routeName,
    Map<String, dynamic>? extra,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    bool ignoreRedirect = false,
    Function(BuildContext)? customHandler,
  })  : _type = type,
        _routeName = routeName,
        _extra = extra,
        _pathParameters = pathParameters,
        _queryParameters = queryParameters,
        _ignoreRedirect = ignoreRedirect,
        _customHandler = customHandler;

  /// Navigate to a named route (FlutterFlow style)
  ///
  /// This is the primary method for simple route navigation in FlutterFlow apps.
  /// It supports all FlutterFlow navigation parameters.
  ///
  /// Parameters:
  /// - [routeName]: The name of the route to navigate to (required)
  /// - [extra]: Extra data to pass to the route (serializable objects)
  /// - [pathParameters]: Path parameters for the route (string key-value pairs)
  /// - [queryParameters]: Query parameters for the route
  /// - [ignoreRedirect]: Whether to ignore redirects (default: false)
  ///
  /// Example:
  /// ```dart
  /// RouteAction.goNamed(
  ///   'ProductPage',
  ///   extra: {'productId': '123'},
  ///   pathParameters: {'id': '123'},
  ///   queryParameters: {'ref': 'campaign'},
  /// )
  /// ```
  static RouteAction goNamed(
    String routeName, {
    Map<String, dynamic>? extra,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
    bool ignoreRedirect = false,
  }) {
    return RouteAction._(
      type: RouteActionType.goNamed,
      routeName: routeName,
      extra: extra,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      ignoreRedirect: ignoreRedirect,
    );
  }

  /// Custom navigation handler with full control
  ///
  /// Use this when you need complex logic or want to use different
  /// navigation methods like pushNamed, pushReplacementNamed, pop, etc.
  ///
  /// The handler receives a [BuildContext] and can perform any navigation
  /// logic. The handler is automatically wrapped in scheduleMicrotask to
  /// prevent navigation-during-build errors.
  ///
  /// Parameters:
  /// - [handler]: Function that receives BuildContext and performs navigation
  ///
  /// Example:
  /// ```dart
  /// RouteAction.custom((context) {
  ///   final productId = someLogic();
  ///   if (productId.isNotEmpty) {
  ///     context.pushNamed('ProductDetails', extra: {'id': productId});
  ///   } else {
  ///     context.goNamed('HomePage');
  ///   }
  /// })
  /// ```
  static RouteAction custom(Function(BuildContext) handler) {
    return RouteAction._(
      type: RouteActionType.custom,
      customHandler: handler,
    );
  }

  /// Execute the navigation action
  ///
  /// This method is called internally by the SDK when a route is matched.
  /// It uses [scheduleMicrotask] to avoid navigation-during-build errors.
  ///
  /// You typically don't need to call this directly - the SDK handles it
  /// when you register routes with [LinkGravityClient.registerRoutes].
  void execute(BuildContext context) {
    scheduleMicrotask(() {
      try {
        switch (_type) {
          case RouteActionType.goNamed:
            // Use dynamic invocation to avoid hard dependency on FlutterFlow
            // The context.goNamed extension comes from FlutterFlow's generated code
            final dynamic ctx = context;
            ctx.goNamed(
              _routeName!,
              extra: _extra,
              pathParameters: _pathParameters,
              queryParameters: _queryParameters,
              ignoreRedirect: _ignoreRedirect,
            );
            break;
          case RouteActionType.custom:
            _customHandler?.call(context);
            break;
        }
      } catch (e) {
        // Rethrow to allow SDK to handle and log the error
        rethrow;
      }
    });
  }

  @override
  String toString() {
    return 'RouteAction(type: $_type, routeName: $_routeName, extra: $_extra)';
  }
}

/// Type of route action
enum RouteActionType {
  /// Navigate using FlutterFlow's goNamed
  goNamed,

  /// Execute custom navigation handler
  custom,
}
