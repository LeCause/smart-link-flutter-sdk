# SDK-004: iOS Attribution Enhancement - SKAdNetwork, IDFA/ATT & Web Fingerprinting

## Story Type
Epic / Technical Enhancement

## Priority
🔴 **HIGH** - Critical for iOS paid acquisition campaigns

---

## Summary

Enhance iOS attribution capabilities to match industry standards (Branch.io, AppsFlyer) by implementing SKAdNetwork 4.0 support, optional IDFA/ATT framework integration, and improved web-to-app fingerprinting with real browser User-Agent collection.

---

## Business Value

### Current Limitations
- **Cannot attribute iOS paid advertising campaigns** (Facebook Ads, Google Ads, TikTok, etc.)
- Attribution accuracy limited to 85-90% even when users consent to tracking
- Weak web-to-app matching due to static User-Agent strings
- **Dealbreaker for clients with iOS paid acquisition budgets**

### Expected Benefits
- ✅ Enable iOS ad campaign attribution via SKAdNetwork
- ✅ Achieve 90-95% attribution accuracy (matching industry leaders)
- ✅ Optional deterministic matching when users grant tracking permission
- ✅ Improved web-to-app fingerprint matching
- ✅ Competitive parity with Branch.io and AppsFlyer

---

## User Stories

### 1. SKAdNetwork Implementation

**As a** mobile marketer running iOS ad campaigns
**I want** LinkGravity SDK to properly report conversions via SKAdNetwork
**So that** I can measure ROI of my Facebook Ads, Google Ads, and TikTok campaigns

**Acceptance Criteria:**
- [ ] Native iOS Swift implementation for SKAdNetwork 4.0+
- [ ] Support conversion value updates (6-bit values)
- [ ] Support SKAdNetwork postback registration
- [ ] Support coarse conversion values (iOS 16.1+)
- [ ] Handle conversion value updates with completion handlers
- [ ] Proper error handling and logging
- [ ] Integration tests with actual app install flow
- [ ] Documentation for marketers on conversion value schema

**Technical Requirements:**
```swift
// Must implement in native iOS plugin
import StoreKit

class SKAdNetworkService {
    // iOS 14.0+
    func updateConversionValue(_ value: Int)

    // iOS 15.4+
    func updatePostbackConversionValue(
        _ fineValue: Int,
        coarseValue: SKAdNetwork.CoarseConversionValue,
        lockWindow: Bool,
        completionHandler: ((Error?) -> Void)?
    )

    // iOS 16.1+
    func updatePostbackConversionValue(
        _ conversionValue: Int,
        coarseValue: SKAdNetwork.CoarseConversionValue,
        lockWindow: Bool
    ) async throws
}
```

**Files to Create/Modify:**
- `ios/Classes/LinkGravityFlutterSdkPlugin.swift` (expand from 20 lines)
- `ios/Classes/SKAdNetworkService.swift` (new)
- `lib/src/services/skadnetwork_service.dart` (replace placeholder)
- Add method channel: `com.linkgravity/skadnetwork`

**Definition of Done:**
- [ ] Code implemented and unit tested
- [ ] Integration test with real ad network postback
- [ ] Documentation updated with SKAdNetwork setup guide
- [ ] Conversion value schema documented
- [ ] Tested on iOS 14.0, 15.4, and 16.1+

---

### 2. IDFA/ATT Framework Integration (Optional)

**As a** mobile app developer
**I want** to optionally request tracking permission from users
**So that** I can achieve 100% attribution accuracy when users consent

**Acceptance Criteria:**
- [ ] Native iOS Swift implementation for ATTrackingManager
- [ ] Request tracking authorization via Flutter API
- [ ] Collect IDFA when user grants permission
- [ ] Send IDFA to backend for deterministic matching
- [ ] Graceful fallback to probabilistic when denied
- [ ] Respect user's tracking preference in Settings
- [ ] Handle "Ask App Not to Track" preference
- [ ] Customizable permission prompt messaging
- [ ] Full GDPR/privacy compliance

**Technical Requirements:**
```swift
import AppTrackingTransparency
import AdSupport

class ATTService {
    // Request permission
    func requestTrackingAuthorization(
        completionHandler: @escaping (ATTrackingManager.AuthorizationStatus) -> Void
    )

    // Get current status
    func getTrackingAuthorizationStatus() -> ATTrackingManager.AuthorizationStatus

    // Get IDFA if authorized
    func getIDFA() -> String?
}
```

**Flutter API Design:**
```dart
// New service
class IDFAService {
  // Request permission (iOS only)
  Future<TrackingAuthorizationStatus> requestTrackingAuthorization() async;

  // Get current status
  Future<TrackingAuthorizationStatus> getTrackingAuthorizationStatus() async;

  // Get IDFA if available
  Future<String?> getIDFA() async;
}

enum TrackingAuthorizationStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
}

// Integration with LinkGravityClient
class LinkGravityClient {
  // Optional: Request tracking before SDK initialization
  Future<void> requestTrackingPermission({
    bool required = false, // If false, continues without permission
  }) async;
}
```

**Files to Create/Modify:**
- `ios/Classes/ATTService.swift` (new)
- `lib/src/services/idfa_service.dart` (new)
- `lib/src/linkgravity_client.dart` (add optional ATT request)
- `lib/src/services/fingerprint_service.dart` (include IDFA when available)
- Add method channel: `com.linkgravity/att`
- Update `Info.plist` documentation for `NSUserTrackingUsageDescription`

**Privacy Considerations:**
- [ ] Make IDFA collection **opt-in** (developer must explicitly enable)
- [ ] Provide clear documentation on privacy implications
- [ ] Include sample `Info.plist` entry for tracking description
- [ ] Default behavior: NO IDFA collection (privacy-first)
- [ ] Allow developers to customize permission prompt text

**Definition of Done:**
- [ ] Code implemented and unit tested
- [ ] Works correctly for all authorization states
- [ ] Privacy manifest updated
- [ ] GDPR compliance verified
- [ ] Documentation includes privacy best practices
- [ ] Example app demonstrates opt-in flow

---

### 3. Real Browser User-Agent Collection

**As a** attribution system
**I want** to collect the actual browser User-Agent from web sessions
**So that** I can improve web-to-app fingerprint matching accuracy

**Current Problem:**
```dart
// lib/src/services/deferred_deep_link_service.dart:328
String _getUserAgent() {
  if (Platform.isIOS) {
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)...';
    // ☝️ STATIC STRING - not actual browser UA!
  }
}
```

**Acceptance Criteria:**
- [ ] JavaScript SDK collects real browser User-Agent
- [ ] User-Agent sent to backend during web click
- [ ] User-Agent stored with click metadata
- [ ] Flutter SDK retrieves User-Agent during fingerprint matching
- [ ] Fallback to generic UA if web UA not available
- [ ] Support for obfuscated UAs (e.g., iOS Privacy features)

**Technical Requirements:**

**Web SDK (JavaScript):**
```javascript
// Collect real User-Agent on web click
const webFingerprint = {
  userAgent: navigator.userAgent,  // Real UA from browser
  platform: navigator.platform,
  vendor: navigator.vendor,
  language: navigator.language,
  languages: navigator.languages,
  hardwareConcurrency: navigator.hardwareConcurrency,
  deviceMemory: navigator.deviceMemory,
  maxTouchPoints: navigator.maxTouchPoints,
  // Additional signals for better matching
  screenResolution: `${screen.width}x${screen.height}`,
  screenColorDepth: screen.colorDepth,
  timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  timezoneOffset: new Date().getTimezoneOffset(),
};

// Send to backend
fetch('https://api.linkgravity.com/v1/clicks', {
  method: 'POST',
  body: JSON.stringify({
    linkId: '...',
    fingerprint: webFingerprint,
    timestamp: Date.now(),
  }),
});
```

**Backend API Changes:**
```json
// POST /v1/clicks - Store web fingerprint
{
  "linkId": "lg_xyz123",
  "fingerprint": {
    "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0...",
    "platform": "iPhone",
    "vendor": "Apple Computer, Inc.",
    "screenResolution": "390x844",
    "timezone": "America/Los_Angeles",
    "timezoneOffset": -480,
    ...
  },
  "timestamp": 1701234567890
}

// GET /v1/deferred-links/match - Return web fingerprint
{
  "match": {
    "confidence": "HIGH",
    "webFingerprint": {
      "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0...",
      ...
    },
    "appFingerprint": {
      "platform": "ios",
      "model": "iPhone14,2",
      ...
    }
  }
}
```

**Flutter SDK Changes:**
```dart
// lib/src/services/deferred_deep_link_service.dart
String _getUserAgent() {
  // 1. Try to get web UA from matched click
  final webUA = _matchedClick?.webFingerprint?.userAgent;
  if (webUA != null && webUA.isNotEmpty) {
    return webUA;  // Use real browser UA
  }

  // 2. Fallback to platform-specific UA
  if (Platform.isIOS) {
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS ${_getIOSVersion()} like Mac OS X)...';
  }
  // ...
}
```

**Files to Create/Modify:**
- Create: `web/linkgravity-web-sdk.js` (new JavaScript SDK)
- Modify: `lib/src/services/deferred_deep_link_service.dart` (line 328)
- Modify: `lib/src/models/deep_link_match.dart` (add webFingerprint field)
- Backend: Update click storage and matching API

**Additional Fingerprinting Signals:**
- [ ] Canvas fingerprinting (optional, privacy-aware)
- [ ] Font enumeration
- [ ] WebGL renderer info
- [ ] Audio context fingerprinting
- [ ] Screen resolution and color depth
- [ ] Hardware concurrency
- [ ] Device memory (if available)

**Definition of Done:**
- [ ] Web SDK collects real User-Agent
- [ ] Backend stores web fingerprint with click
- [ ] Flutter SDK uses web UA for matching
- [ ] Attribution accuracy improved (measure before/after)
- [ ] Privacy compliance verified
- [ ] Documentation for web SDK integration
- [ ] Example web page demonstrates integration

---

## Technical Architecture

### System Overview

```
┌─────────────────┐
│   Web Browser   │
│  (User clicks)  │
└────────┬────────┘
         │ 1. Click + Web Fingerprint
         │    (real User-Agent, etc.)
         ▼
┌─────────────────────────┐
│  LinkGravity Backend    │
│  - Store web fingerprint│
│  - Store click metadata │
└────────┬────────────────┘
         │
         │ 2. User installs app
         │
         ▼
┌─────────────────────────┐
│   iOS App (Flutter)     │
│  - Request ATT (opt)    │
│  - Collect IDFA (opt)   │
│  - Collect app FP       │
└────────┬────────────────┘
         │ 3. App Fingerprint
         │    + IDFA (if authorized)
         ▼
┌─────────────────────────┐
│  LinkGravity Backend    │
│  - Match fingerprints   │
│  - Deterministic (IDFA) │
│    OR Probabilistic     │
└────────┬────────────────┘
         │ 4. Matched deep link
         ▼
┌─────────────────────────┐
│   iOS App (Flutter)     │
│  - Navigate to content  │
│  - Update SKAdNetwork   │
└─────────────────────────┘
```

### Matching Priority

```
1. IDFA Match (if available)
   └─> 100% accuracy, deterministic

2. IDFV Match
   └─> High accuracy for same vendor

3. Enhanced Fingerprint Match
   ├─> Real User-Agent from web
   ├─> Device model + OS version
   ├─> Timezone + Locale
   └─> Time window + behavioral signals
   └─> 90-95% accuracy

4. Fallback: Basic Fingerprint
   └─> 85-90% accuracy
```

---

## Implementation Plan

### Phase 1: SKAdNetwork (Week 1-2)
- [ ] Spike: Research SKAdNetwork 4.0 API
- [ ] Implement native iOS Swift service
- [ ] Create Flutter method channel
- [ ] Write unit tests
- [ ] Integration test with ad network
- [ ] Document conversion value schema

### Phase 2: IDFA/ATT (Week 2-3)
- [ ] Spike: Review ATTrackingManager best practices
- [ ] Implement native iOS ATT service
- [ ] Create Flutter API for permission request
- [ ] Integrate IDFA into fingerprint collection
- [ ] Update backend matching logic (deterministic path)
- [ ] Privacy compliance review
- [ ] Documentation and example app

### Phase 3: Web Fingerprinting (Week 3-4)
- [ ] Create JavaScript web SDK
- [ ] Update backend click storage schema
- [ ] Modify Flutter SDK to use web UA
- [ ] Add additional fingerprinting signals
- [ ] A/B test attribution accuracy improvement
- [ ] Documentation for web integration

### Phase 4: Testing & Documentation (Week 4-5)
- [ ] End-to-end testing across all features
- [ ] Performance testing
- [ ] Privacy compliance audit
- [ ] Documentation review
- [ ] Release notes
- [ ] Migration guide for existing clients

---

## Testing Strategy

### Unit Tests
- [ ] SKAdNetwork conversion value updates
- [ ] ATT permission request states
- [ ] IDFA retrieval logic
- [ ] Web fingerprint parsing
- [ ] Fingerprint matching algorithm

### Integration Tests
- [ ] Real ad network SKAdNetwork postback
- [ ] ATT permission flow on real device
- [ ] Web-to-app attribution flow
- [ ] IDFA-based deterministic matching
- [ ] Fallback to probabilistic matching

### Edge Cases
- [ ] User denies tracking permission
- [ ] IDFV unavailable (all vendor apps deleted)
- [ ] Web UA unavailable (direct app install)
- [ ] VPN/proxy usage
- [ ] Cross-timezone attribution
- [ ] iOS Privacy features (Private Relay, etc.)

---

## Privacy & Compliance

### GDPR/Privacy Requirements
- [ ] IDFA collection is **opt-in only** (developer choice)
- [ ] Clear documentation of privacy implications
- [ ] User consent must be obtained before ATT request
- [ ] Data minimization: only collect necessary signals
- [ ] Data retention policies documented
- [ ] Right to deletion supported

### iOS Privacy Manifest
- [ ] Update `PrivacyInfo.xcprivacy` with required APIs
- [ ] Declare User Tracking usage (if IDFA enabled)
- [ ] Document data collection purposes

### App Store Requirements
- [ ] `NSUserTrackingUsageDescription` in Info.plist
- [ ] Privacy nutrition labels guidance
- [ ] ATT prompt best practices documented

---

## Success Metrics

### Before (Current State)
- ❌ No SKAdNetwork support → Cannot attribute iOS ads
- 📊 Attribution accuracy: 85-90% (probabilistic only)
- 📊 Web-to-app matching: Weak (static User-Agent)
- ❌ Cannot use IDFA even when users consent

### After (Target State)
- ✅ Full SKAdNetwork 4.0 support → iOS ad attribution enabled
- 📊 Attribution accuracy: 90-95% (with IDFA) or 85-90% (without)
- 📊 Web-to-app matching: Improved (real User-Agent)
- ✅ Optional deterministic matching via IDFA
- 🎯 **Competitive parity with Branch.io and AppsFlyer**

### KPIs to Track
- Attribution accuracy rate (pre vs. post implementation)
- SKAdNetwork conversion tracking success rate
- IDFA authorization grant rate (when requested)
- Web-to-app fingerprint match confidence distribution
- Time-to-install impact on match accuracy

---

## Dependencies

### External
- iOS 14.0+ (for SKAdNetwork)
- iOS 14.5+ (for ATTrackingManager)
- Ad network integration (Facebook, Google, TikTok)
- Backend API updates

### Internal
- `device_info_plus` package (already used)
- `crypto` package (already used for fingerprinting)
- New native iOS Swift code

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Low ATT consent rate | Medium | High | Make IDFA optional, maintain privacy-first default |
| SKAdNetwork API changes | High | Medium | Use version detection, support multiple iOS versions |
| Privacy regulation changes | High | Low | Legal review, build flexibility for compliance |
| Web SDK adoption friction | Medium | Medium | Provide CDN-hosted SDK, simple integration docs |
| Backend performance | Medium | Low | Optimize fingerprint matching, add caching |

---

## Documentation Requirements

### Developer Documentation
- [ ] SKAdNetwork setup guide
- [ ] Conversion value schema examples
- [ ] ATT integration guide (with code samples)
- [ ] Privacy best practices
- [ ] Web SDK integration guide
- [ ] Migration guide from v1.x to v2.x

### Marketing Documentation
- [ ] Feature comparison with Branch.io/AppsFlyer
- [ ] Privacy-first positioning
- [ ] Use cases for paid acquisition

### API Reference
- [ ] `SKAdNetworkService` API docs
- [ ] `IDFAService` API docs
- [ ] Updated `LinkGravityClient` API docs
- [ ] Web SDK JavaScript API reference

---

## Related Issues

- SDK-002: Backend-Flutter SDK alignment
- SDK-003: Simplify Deep Link Route Registration
- PRIVACY-001: Privacy-first deferred deep linking guide
- LINK-005: Native Android implementation (already complete)

---

## Acceptance Criteria (Epic Level)

- [ ] All three features implemented and tested
- [ ] Attribution accuracy improved to 90-95% (when IDFA available)
- [ ] SKAdNetwork conversions tracked successfully
- [ ] Privacy compliance verified (GDPR, CCPA, iOS)
- [ ] Documentation complete and reviewed
- [ ] Example app demonstrates all features
- [ ] Backward compatible with existing SDK usage
- [ ] Performance benchmarks meet targets (<100ms overhead)
- [ ] Ready for production deployment

---

## Effort Estimate

- **Story Points:** 34 (Epic)
- **Time Estimate:** 4-5 weeks (1 senior iOS/Flutter developer)
- **Complexity:** High (native iOS + Flutter + backend integration)

---

## Labels
`ios` `attribution` `skadnetwork` `idfa` `privacy` `enhancement` `high-priority`

---

## Questions for Product Owner

1. Should IDFA collection be opt-in by default or configurable?
   - **Recommendation:** Opt-in, privacy-first by default

2. What should be our SKAdNetwork conversion value schema?
   - Example: 0-20 (in-app events), 21-40 (purchases), 41-63 (LTV tiers)

3. Do we need to support older iOS versions (<14.0)?
   - SKAdNetwork requires iOS 14.0+, ATT requires iOS 14.5+

4. Should we build a JavaScript web SDK or provide integration guide for existing tracking?
   - **Recommendation:** Build simple JS SDK for easy adoption

5. What's the priority order if we need to phase implementation?
   - **Recommendation:** SKAdNetwork → Web UA → IDFA (in that order)

---

## Notes

- This epic brings LinkGravity SDK to **feature parity** with Branch.io and AppsFlyer for core iOS attribution
- Privacy-first approach remains a key differentiator
- SKAdNetwork is **critical** for any client running iOS paid acquisition
- IDFA support is optional but important for clients who want maximum accuracy
- Web fingerprinting improvements benefit all users, even without IDFA

---

**Created:** 2025-11-28
**Updated:** 2025-11-28
**Author:** Development Team
**Status:** Ready for Estimation
