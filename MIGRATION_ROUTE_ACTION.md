# RouteAction Migration Guide

## Breaking Change in v1.0.1

The `RouteAction` API has been simplified to use a callback-only pattern. This removes the dependency on `go_router` and provides maximum flexibility for all navigation systems.

---

## What Changed?

### Before (v1.0.0):
```dart
RouteAction.goNamed('ProductPage', extra: {'id': '123'})
RouteAction.custom((context) => context.goNamed('ProductPage'))
```

### After (v1.0.1+):
```dart
RouteAction((context, deepLink) {
  context.goNamed('ProductPage', extra: {'id': deepLink.getParam('id')});
})
```

---

## Migration Steps

### Step 1: Update Your Route Registration

**Old Code:**
```dart
LinkGravityClient.instance.registerRoutes(
  context: context,
  routes: {
    '/hidden': (deepLink) => RouteAction.goNamed(
          'HiddenDeepLinkPage',
          extra: {'ref': deepLink.getParam('ref')},
        ),
    '/hidden2': (deepLink) => RouteAction.goNamed(
          'HiddenDeepLinkPage2',
          extra: {'ref': deepLink.getParam('ref')},
        ),
  },
);
```

**New Code:**
```dart
LinkGravityClient.instance.registerRoutes(
  context: context,
  routes: {
    '/hidden': (deepLink) => RouteAction((ctx, data) {
          ctx.goNamed(
            'HiddenDeepLinkPage',
            extra: {'ref': data.getParam('ref')},
          );
        }),
    '/hidden2': (deepLink) => RouteAction((ctx, data) {
          ctx.goNamed(
            'HiddenDeepLinkPage2',
            extra: {'ref': data.getParam('ref')},
          );
        }),
  },
);
```

### Step 2: Combine Multiple Route Registrations (Optional)

If you had multiple `attachSmartLinkListener` calls, you can now combine them into one:

**Old Code:**
```dart
// First call
Future attachSmartLinkListener1(BuildContext context) async {
  LinkGravityClient.instance.registerRoutes(
    context: context,
    routes: {'/hidden': ...},
  );
}

// Second call
Future attachSmartLinkListener2(BuildContext context) async {
  LinkGravityClient.instance.registerRoutes(
    context: context,
    routes: {'/hidden2': ...},
  );
}
```

**New Code (Recommended):**
```dart
// Single unified call
Future attachSmartLinkListener(BuildContext context) async {
  LinkGravityClient.instance.registerRoutes(
    context: context,
    routes: {
      '/hidden': (deepLink) => RouteAction((ctx, data) {
        ctx.goNamed('HiddenDeepLinkPage', extra: {'ref': data.getParam('ref')});
      }),
      '/hidden2': (deepLink) => RouteAction((ctx, data) {
        ctx.goNamed('HiddenDeepLinkPage2', extra: {'ref': data.getParam('ref')});
      }),
      // Add more routes here...
    },
  );
}
```

---

## Benefits of the New API

### ✅ No Package Dependencies
- No dependency on `go_router` or any specific navigation package
- Works with **any** navigation system

### ✅ Works with Any Navigation System

**FlutterFlow with go_router:**
```dart
RouteAction((ctx, data) {
  ctx.goNamed('ProductPage', extra: data.params);
})
```

**Standard Flutter Navigator:**
```dart
RouteAction((ctx, data) {
  Navigator.of(ctx).pushNamed('/product', arguments: data.params);
})
```

**AutoRoute:**
```dart
RouteAction((ctx, data) {
  ctx.router.push(ProductRoute(id: data.getParam('id')));
})
```

**Beamer:**
```dart
RouteAction((ctx, data) {
  Beamer.of(ctx).beamToNamed('/product/${data.getParam('id')}');
})
```

### ✅ No Context Issues
- Context is passed fresh on each navigation
- No "StatefulElement has no goNamed method" errors
- Context is always valid and mounted

### ✅ Simpler Code
- Less code to maintain
- Clearer what's happening
- Easier to debug

---

## Advanced Example

Create a helper function for common patterns:

```dart
// Helper for FlutterFlow navigation
RouteAction navigateToPage(String pageName, Map<String, dynamic> Function(DeepLinkData) extraBuilder) {
  return RouteAction((ctx, data) {
    ctx.goNamed(pageName, extra: extraBuilder(data));
  });
}

// Usage becomes very concise:
LinkGravityClient.instance.registerRoutes(
  context: context,
  routes: {
    '/product': (deepLink) => navigateToPage(
      'ProductPage',
      (data) => {'id': data.getParam('id')},
    ),
    '/user': (deepLink) => navigateToPage(
      'UserPage',
      (data) => {'userId': data.getParam('userId')},
    ),
  },
);
```

---

## Questions?

If you encounter any issues during migration, please file an issue on GitHub:
https://github.com/yourusername/linkgravity_flutter_sdk/issues
