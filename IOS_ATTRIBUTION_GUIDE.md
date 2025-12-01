# iOS Attribution Guide - SKAdNetwork & IDFA/ATT

Complete guide for implementing iOS attribution with SKAdNetwork 4.0 and optional IDFA tracking.

## Table of Contents

1. [Overview](#overview)
2. [SKAdNetwork Implementation](#skadnetwork-implementation)
3. [IDFA/ATT Framework (Optional)](#idfa-att-framework-optional)
4. [Setup Instructions](#setup-instructions)
5. [Usage Examples](#usage-examples)
6. [Conversion Value Schema](#conversion-value-schema)
7. [Privacy & Compliance](#privacy--compliance)
8. [Troubleshooting](#troubleshooting)

---

## Overview

LinkGravity SDK now supports **two iOS attribution methods**:

### 1. SKAdNetwork (Required for iOS Ad Attribution)
- **Purpose**: Track conversions from iOS ad campaigns
- **Privacy**: Completely private, no user-level tracking
- **Accuracy**: Campaign-level attribution only
- **Required for**: Facebook Ads, Google Ads, TikTok, etc.
- **Availability**: iOS 14.0+

### 2. IDFA/ATT (Optional for Deterministic Attribution)
- **Purpose**: 100% accurate user-level attribution (when authorized)
- **Privacy**: Requires user consent via ATT prompt
- **Accuracy**: 100% deterministic (vs 85-90% probabilistic)
- **Optional**: SDK works without IDFA
- **Availability**: iOS 14.5+

### Attribution Flow

```
┌─────────────────┐
│   Web Click     │
│  (Fingerprint)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  User Installs  │
│   App (iOS)     │
└────────┬────────┘
         │
         ├──────────────┐
         │              │
         ▼              ▼
┌─────────────┐  ┌──────────────┐
│ ATT         │  │ Fingerprint  │
│ (IDFA)      │  │ Matching     │
│ if allowed  │  │ (fallback)   │
└──────┬──────┘  └──────┬───────┘
       │                │
       ▼                ▼
  100% Match       85-90% Match
       │                │
       └───────┬────────┘
               ▼
      ┌─────────────────┐
      │ Deep Link Open  │
      └────────┬─────────┘
               │
               ▼
      ┌─────────────────┐
      │  SKAdNetwork    │
      │  Conversion     │
      │  Value Update   │
      └─────────────────┘
```

---

## SKAdNetwork Implementation

### What is SKAdNetwork?

SKAdNetwork is Apple's privacy-preserving ad attribution framework. It allows you to measure iOS ad campaign effectiveness without user-level tracking.

**Key Features:**
- No access to user data or device IDs
- Campaign-level attribution only
- Conversion values (0-63) report in-app events
- Postbacks sent directly to ad networks

### Step 1: iOS Project Setup

#### Add SKAdNetwork IDs to Info.plist

Add the SKAdNetwork IDs of your ad partners to `ios/Runner/Info.plist`:

```xml
<key>SKAdNetworkItems</key>
<array>
    <!-- Facebook -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v9wttpbfk9.skadnetwork</string>
    </dict>
    <!-- Google Ads -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <!-- TikTok -->
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>22mmun2rn5.skadnetwork</string>
    </dict>
    <!-- Add more ad networks as needed -->
</array>
```

**Get complete list:**
- Facebook: https://developers.facebook.com/docs/SKAdNetwork
- Google: https://developers.google.com/admob/ios/ios14#skadnetwork
- TikTok: https://ads.tiktok.com/help/article?aid=10000407

### Step 2: Update Conversion Values

Update conversion values when users complete important actions:

```dart
import 'package:linkgravity_flutter_sdk/linkgravity_flutter_sdk.dart';

// Initialize SDK
final linkGravity = await LinkGravityClient.initialize(
  baseUrl: 'https://api.linkgravity.io',
  apiKey: 'your-api-key',
);

// User completed tutorial
await linkGravity.updateConversionValue(10);

// User made first purchase
await linkGravity.updateConversionValue(25);

// User reached high LTV tier
await linkGravity.updateConversionValue(50);
```

### Step 3: Advanced Conversion Tracking (iOS 15.4+)

For more granular tracking, use postback conversion values:

```dart
// High-value conversion
await linkGravity.updatePostbackConversionValue(
  fineValue: 42,           // Specific event value (0-63)
  coarseValue: 'high',     // Coarse tier: 'low', 'medium', 'high'
  lockWindow: false,       // Lock to prevent further updates
);

// Lock window after critical conversion
await linkGravity.updatePostbackConversionValue(
  fineValue: 63,
  coarseValue: 'high',
  lockWindow: true,  // No more updates allowed
);
```

---

## IDFA/ATT Framework (Optional)

### What is IDFA/ATT?

**IDFA** (Identifier for Advertisers) is a unique device ID for advertising.
**ATT** (App Tracking Transparency) is the framework for requesting user permission.

**When to use:**
- ✅ You want 100% accurate attribution (vs 85-90% probabilistic)
- ✅ You run paid user acquisition campaigns
- ✅ You're willing to ask users for permission
- ⚠️ Be aware: ~15-25% of users grant permission (industry average)

**When NOT to use:**
- ❌ You want maximum privacy (LinkGravity works great without IDFA!)
- ❌ You don't run paid ads
- ❌ You want to avoid the permission prompt

### Step 1: Add Usage Description

Add tracking usage description to `ios/Runner/Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We'd like to show you personalized content and measure ad effectiveness. Your data will be used to improve your experience.</string>
```

**Best Practices for the message:**
- ✅ Explain the benefit to the user
- ✅ Be honest and transparent
- ✅ Keep it concise (1-2 sentences)
- ❌ Don't be vague or misleading
- ❌ Don't mention "tracking" without context

**Good Examples:**
```
"Help us show you more relevant content and measure our marketing effectiveness."

"This helps us understand which marketing channels bring users like you, so we can invest in creating better experiences."

"We use this to attribute app installs to the correct marketing campaign and personalize your experience."
```

**Bad Examples:**
```
"We need this for tracking." ❌ (Too vague)
"Required for app functionality." ❌ (Misleading)
"Allow tracking to continue." ❌ (Sounds forced)
```

### Step 2: Request Permission at the Right Time

**❌ DON'T request immediately on app launch:**
```dart
// BAD - Don't do this!
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final linkGravity = await LinkGravityClient.initialize(...);

  // Too early! User doesn't understand the value yet
  await linkGravity.requestTrackingAuthorization(); // ❌

  runApp(MyApp());
}
```

**✅ DO request after user sees value:**
```dart
// GOOD - Request at the right moment
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    _requestTrackingWhenReady();
  }

  Future<void> _requestTrackingWhenReady() async {
    // Wait for user to finish onboarding
    await _completeOnboarding();

    // Show custom explanation dialog first
    final shouldAsk = await _showTrackingExplanationDialog();

    if (shouldAsk) {
      // Now request system permission
      final status = await LinkGravityClient.instance
          .requestTrackingAuthorization();

      if (status == TrackingAuthorizationStatus.authorized) {
        print('✅ User granted tracking permission');
      } else {
        print('❌ User denied tracking - will use fingerprinting');
      }
    }
  }

  Future<bool> _showTrackingExplanationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help Us Improve'),
        content: Text(
          'We\'d like to measure which marketing channels work best. '
          'This helps us create better experiences for users like you. '
          'You can always change this in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not Now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _completeOnboarding() async {
    // User completes tutorial, sees app value, etc.
    await Future.delayed(Duration(seconds: 3));
  }
}
```

### Step 3: Check Status Before Requesting

Always check current status to avoid redundant prompts:

```dart
Future<void> requestTrackingIfNeeded() async {
  final linkGravity = LinkGravityClient.instance;

  // Check current status
  final status = await linkGravity.getTrackingAuthorizationStatus();

  switch (status) {
    case TrackingAuthorizationStatus.notDetermined:
      // User hasn't been asked yet - good time to request
      print('User hasn\'t been asked yet');
      final newStatus = await linkGravity.requestTrackingAuthorization();
      print('New status: $newStatus');
      break;

    case TrackingAuthorizationStatus.authorized:
      // Already authorized - no need to ask again
      print('✅ Already authorized');
      final idfa = await linkGravity.getIDFA();
      print('IDFA: $idfa');
      break;

    case TrackingAuthorizationStatus.denied:
      // User explicitly denied - respect their choice
      print('❌ User denied tracking');
      print('Using probabilistic attribution');
      break;

    case TrackingAuthorizationStatus.restricted:
      // Restricted by parental controls, etc.
      print('⚠️ Tracking restricted (parental controls, MDM, etc.)');
      break;
  }
}
```

### Step 4: Get IDFA When Authorized

```dart
Future<void> checkIDFAAvailability() async {
  final linkGravity = LinkGravityClient.instance;

  final idfa = await linkGravity.getIDFA();

  if (idfa != null) {
    print('✅ IDFA available: $idfa');
    print('Using deterministic attribution (100% accuracy)');
  } else {
    print('❌ IDFA not available');
    print('Using probabilistic attribution (85-90% accuracy)');
  }
}
```

---

## Setup Instructions

### Complete Setup Checklist

#### 1. Update `pubspec.yaml`

No changes needed - SKAdNetwork and IDFA services are included!

#### 2. Update `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->

    <!-- SKAdNetwork IDs (Required for ad attribution) -->
    <key>SKAdNetworkItems</key>
    <array>
        <!-- Add your ad network IDs here -->
        <dict>
            <key>SKAdNetworkIdentifier</key>
            <string>v9wttpbfk9.skadnetwork</string>
        </dict>
        <!-- Add more... -->
    </array>

    <!-- ATT Usage Description (Optional - only if using IDFA) -->
    <key>NSUserTrackingUsageDescription</key>
    <string>We'd like to show you personalized content and measure ad effectiveness.</string>

</dict>
</plist>
```

#### 3. Initialize SDK in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:linkgravity_flutter_sdk/linkgravity_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize LinkGravity SDK
  final linkGravity = await LinkGravityClient.initialize(
    baseUrl: 'https://api.linkgravity.io',
    apiKey: 'your-api-key',
  );

  // Check SKAdNetwork availability
  final skadAvailable = await linkGravity.isSKAdNetworkAvailable();
  print('SKAdNetwork available: $skadAvailable');

  runApp(MyApp());
}
```

#### 4. Request ATT Permission (Optional)

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestTrackingAfterOnboarding();
  }

  Future<void> _requestTrackingAfterOnboarding() async {
    // Wait for user to see app value
    await Future.delayed(Duration(seconds: 5));

    final linkGravity = LinkGravityClient.instance;
    final status = await linkGravity.getTrackingAuthorizationStatus();

    if (status == TrackingAuthorizationStatus.notDetermined) {
      await linkGravity.requestTrackingAuthorization();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

#### 5. Update Conversion Values

```dart
class ProductDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Premium Widget')),
      body: Column(
        children: [
          Text('Premium Widget - \$99'),
          ElevatedButton(
            onPressed: () async {
              // User made purchase
              await _handlePurchase();
            },
            child: Text('Buy Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    final linkGravity = LinkGravityClient.instance;

    // Update SKAdNetwork conversion value
    await linkGravity.updateConversionValue(25); // Purchase event

    // Process purchase...
  }
}
```

---

## Usage Examples

### Example 1: E-commerce App

```dart
class ShoppingApp {
  final LinkGravityClient linkGravity;

  ShoppingApp(this.linkGravity);

  // Conversion Value Schema:
  // 0-10: Tutorial & onboarding
  // 11-20: Product views & engagement
  // 21-30: Purchases (tiered by value)
  // 31-40: Repeat purchases
  // 41-63: LTV tiers

  Future<void> onTutorialComplete() async {
    await linkGravity.updateConversionValue(10);
  }

  Future<void> onProductView() async {
    await linkGravity.updateConversionValue(15);
  }

  Future<void> onPurchase(double amount) async {
    if (amount < 20) {
      await linkGravity.updateConversionValue(21); // Small purchase
    } else if (amount < 50) {
      await linkGravity.updateConversionValue(25); // Medium purchase
    } else {
      await linkGravity.updateConversionValue(30); // Large purchase
    }
  }

  Future<void> onRepeatPurchase() async {
    await linkGravity.updateConversionValue(35);
  }

  Future<void> onHighLTV() async {
    // User reached $500 lifetime value
    await linkGravity.updatePostbackConversionValue(
      fineValue: 50,
      coarseValue: 'high',
      lockWindow: true, // Lock - no more updates
    );
  }
}
```

### Example 2: Subscription App

```dart
class SubscriptionApp {
  final LinkGravityClient linkGravity;

  SubscriptionApp(this.linkGravity);

  // Conversion Value Schema:
  // 0-10: Trial started
  // 11-20: Trial engagement
  // 21-30: Subscription started
  // 31-40: Subscription retention
  // 41-63: LTV tiers

  Future<void> onTrialStart() async {
    await linkGravity.updateConversionValue(5);
  }

  Future<void> onTrialActive(int daysActive) async {
    if (daysActive >= 7) {
      await linkGravity.updateConversionValue(15);
    }
  }

  Future<void> onSubscriptionStart(String tier) async {
    switch (tier) {
      case 'monthly':
        await linkGravity.updateConversionValue(21);
        break;
      case 'yearly':
        await linkGravity.updateConversionValue(25);
        break;
      case 'premium':
        await linkGravity.updateConversionValue(30);
        break;
    }
  }

  Future<void> onSubscriptionRenewal(int renewalCount) async {
    final value = 30 + min(renewalCount, 10);
    await linkGravity.updateConversionValue(value);
  }

  Future<void> onHighLTV() async {
    await linkGravity.updatePostbackConversionValue(
      fineValue: 63,
      coarseValue: 'high',
      lockWindow: true,
    );
  }
}
```

### Example 3: Gaming App

```dart
class GamingApp {
  final LinkGravityClient linkGravity;

  GamingApp(this.linkGravity);

  // Conversion Value Schema:
  // 0-10: Tutorial & first level
  // 11-20: Level progression
  // 21-30: In-app purchases
  // 31-40: Social features (invites, etc.)
  // 41-63: Retention & LTV

  Future<void> onTutorialComplete() async {
    await linkGravity.updateConversionValue(10);
  }

  Future<void> onLevelComplete(int level) async {
    if (level == 5) {
      await linkGravity.updateConversionValue(12);
    } else if (level == 10) {
      await linkGravity.updateConversionValue(15);
    } else if (level == 20) {
      await linkGravity.updateConversionValue(20);
    }
  }

  Future<void> onIAPPurchase(String item) async {
    switch (item) {
      case 'coins_small':
        await linkGravity.updateConversionValue(21);
        break;
      case 'coins_large':
        await linkGravity.updateConversionValue(25);
        break;
      case 'premium_pass':
        await linkGravity.updateConversionValue(30);
        break;
    }
  }

  Future<void> onUserRetained(int days) async {
    if (days == 7) {
      await linkGravity.updateConversionValue(45);
    } else if (days == 14) {
      await linkGravity.updateConversionValue(50);
    } else if (days == 30) {
      await linkGravity.updatePostbackConversionValue(
        fineValue: 60,
        coarseValue: 'high',
        lockWindow: false,
      );
    }
  }
}
```

---

## Conversion Value Schema

### Designing Your Schema

A good conversion value schema maps your 0-63 range to meaningful business events.

#### Best Practices:

1. **Start Simple**: Map basic funnel stages first
2. **Reserve High Values**: Save 50-63 for high-value events
3. **Be Consistent**: Use similar ranges across campaigns
4. **Document Everything**: Share schema with marketing team

#### Template Schema:

```
0-10:   Onboarding & Tutorial
11-20:  Engagement & Feature Usage
21-30:  First Conversion (purchase, subscription, etc.)
31-40:  Repeat Conversions
41-50:  Retention Milestones (7d, 14d, 30d)
51-63:  High LTV Tiers
```

#### Example Schemas by Vertical:

**E-commerce:**
```
0:  App opened
5:  Tutorial complete
10: First product view
15: Added to cart
20: Abandoned cart recovered
25: First purchase ($0-50)
30: First purchase ($50-100)
35: First purchase ($100+)
40: Repeat purchase
45: 3+ purchases
50: 5+ purchases
55: LTV $100+
60: LTV $500+
63: LTV $1000+ (lock)
```

**Subscription:**
```
0:  App opened
5:  Trial started
10: Feature engagement
15: Trial day 3 active
20: Trial day 7 active
25: Monthly subscription
30: Yearly subscription
35: First renewal
40: Second renewal
45: Third renewal
50: 6-month retention
55: 12-month retention
60: 18-month retention
63: 24-month retention (lock)
```

**Social/Content:**
```
0:  App opened
5:  Profile created
10: First post/content
15: 5 posts
20: First social interaction
25: 10 social interactions
30: Invited friend
35: Premium upgrade
40: 7-day retention
45: 14-day retention
50: 30-day retention
55: 60-day retention
60: 90-day retention
63: Power user (lock)
```

---

## Privacy & Compliance

### SKAdNetwork Privacy

✅ **Fully Private**
- No user-level data
- No device IDs
- No cross-app tracking
- Campaign-level only
- Approved by Apple

### IDFA/ATT Privacy

⚠️ **Requires User Consent**
- User must explicitly grant permission
- Can be revoked in Settings
- Optional (app works without it)
- Must have valid usage description
- Subject to App Store review

### Privacy Best Practices

1. **Be Transparent**
   - Clearly explain why you need tracking permission
   - Update privacy policy to mention IDFA usage
   - Provide easy opt-out in app settings

2. **Respect User Choice**
   - Never repeatedly prompt if denied
   - App must work perfectly without IDFA
   - Don't restrict features if user denies

3. **Minimize Data Collection**
   - Only use IDFA if you really need it
   - Consider if probabilistic attribution is enough
   - Don't collect more data than necessary

4. **Comply with Regulations**
   - GDPR (Europe): Get consent before tracking
   - CCPA (California): Provide opt-out mechanism
   - App Store Guidelines: Follow ATT requirements

### App Store Review

**Common Rejection Reasons:**
- ❌ Missing `NSUserTrackingUsageDescription`
- ❌ Vague or misleading usage description
- ❌ Requesting ATT before showing app value
- ❌ Restricting features if user denies
- ❌ Using IDFA without requesting permission

**How to Pass Review:**
- ✅ Clear, honest usage description
- ✅ Request permission at appropriate time
- ✅ App works fully without IDFA
- ✅ Respect user's choice

---

## Troubleshooting

### SKAdNetwork Issues

#### Conversion values not updating

**Check:**
```dart
// 1. Verify SKAdNetwork is available
final available = await linkGravity.isSKAdNetworkAvailable();
print('SKAdNetwork available: $available');

// 2. Check iOS version
final version = await linkGravity.getSKAdNetworkVersion();
print('SKAdNetwork version: $version');

// 3. Verify conversion value is valid (0-63)
final success = await linkGravity.updateConversionValue(25);
print('Update success: $success');
```

**Common Fixes:**
- Ensure iOS 14.0+ (check `getSKAdNetworkVersion()`)
- Verify conversion value is 0-63
- Check Info.plist has SKAdNetwork IDs

#### Not receiving postbacks

**Postbacks go to ad networks, not your app!**
- Postbacks are sent by Apple to the ad network (Facebook, Google, etc.)
- You see results in your ad network dashboard
- Can take 24-72 hours for first postback
- No way to test postbacks in development

### IDFA/ATT Issues

#### Permission dialog not showing

**Check:**
```dart
// 1. Verify ATT is available
final linkGravity = LinkGravityClient.instance;
final status = await linkGravity.getTrackingAuthorizationStatus();
print('Current status: $status');

// 2. Check Info.plist
// Make sure NSUserTrackingUsageDescription exists
```

**Common Fixes:**
- Add `NSUserTrackingUsageDescription` to Info.plist
- Can only request once per install
- Dialog won't show if status is already determined
- Reset device: Settings → General → Reset → Reset Location & Privacy

#### IDFA is null even when authorized

**Check:**
```dart
final status = await linkGravity.getTrackingAuthorizationStatus();
print('Status: $status');

if (status == TrackingAuthorizationStatus.authorized) {
  final idfa = await linkGravity.getIDFA();
  print('IDFA: $idfa');

  if (idfa == null) {
    print('⚠️ IDFA is zero UUID (privacy protection)');
  }
}
```

**Common Causes:**
- Limit Ad Tracking enabled in Settings
- Device restrictions (parental controls, MDM)
- Simulator (IDFA is always 00000000...)
- Privacy protection feature

#### Permission always returns .notDetermined

**You can only request permission ONCE per install!**

Reset permission state:
1. Delete app
2. Settings → General → Reset → Reset Location & Privacy
3. Reinstall app
4. Try again

### Debugging

#### Enable debug logging

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final linkGravity = await LinkGravityClient.initialize(
    baseUrl: 'https://api.linkgravity.io',
    apiKey: 'your-api-key',
    config: LinkGravityConfig(
      logLevel: LogLevel.debug, // Enable debug logs
    ),
  );

  runApp(MyApp());
}
```

#### Get comprehensive attribution info

```dart
Future<void> debugAttribution() async {
  final linkGravity = LinkGravityClient.instance;

  // Get all iOS attribution info
  final info = await linkGravity.getIOSAttributionInfo();
  print('iOS Attribution Info:');
  print(json.encode(info, indent: 2));

  // Output:
  // {
  //   "platform": "iOS",
  //   "skadnetwork": {
  //     "available": true,
  //     "version": "4.0",
  //     "supportsPostback": true
  //   },
  //   "att": {
  //     "available": true,
  //     "status": "authorized",
  //     "trackingEnabled": true,
  //     "idfa": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  //   }
  // }
}
```

---

## Summary

### What You Need to Do

#### Minimum (SKAdNetwork Only):
1. ✅ Add SKAdNetwork IDs to Info.plist
2. ✅ Call `updateConversionValue()` for key events
3. ✅ Design conversion value schema (0-63)

#### Optional (IDFA for Better Accuracy):
4. ✅ Add `NSUserTrackingUsageDescription` to Info.plist
5. ✅ Request permission at the right time
6. ✅ Handle all authorization states gracefully

### Expected Results

**Without IDFA:**
- ✅ 85-90% attribution accuracy (probabilistic)
- ✅ SKAdNetwork campaign tracking
- ✅ Full privacy compliance
- ✅ No permission prompts

**With IDFA (when authorized):**
- ✅ 100% attribution accuracy (deterministic)
- ✅ SKAdNetwork campaign tracking
- ✅ User consented to tracking
- ⚠️ Only ~15-25% of users grant permission

### Need Help?

- 📖 Documentation: https://docs.linkgravity.io
- 💬 GitHub Issues: https://github.com/linkgravity/flutter-sdk/issues
- 📧 Email: support@linkgravity.io

---

**Made with ❤️ by the LinkGravity Team**
