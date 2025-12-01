# LinkGravity Web SDK

The LinkGravity Web SDK collects detailed browser fingerprints for improved web-to-app attribution matching.

## Features

- **Real User-Agent Collection**: Captures actual browser User-Agent instead of static strings
- **Comprehensive Fingerprinting**: Collects 20+ browser signals for accurate matching
- **Privacy-Aware**: Optional canvas/WebGL fingerprinting, respects Do Not Track
- **Easy Integration**: Auto-track links or manual API
- **Lightweight**: ~5KB minified

## Quick Start

### 1. Include the SDK

```html
<!-- CDN (recommended) -->
<script src="https://cdn.linkgravity.io/web-sdk/v1/linkgravity-web-sdk.js"></script>

<!-- Or self-hosted -->
<script src="/path/to/linkgravity-web-sdk.js"></script>
```

### 2. Auto-Track Links

Add `data-linkgravity-id` attribute to your links and `data-linkgravity-auto` to enable auto-tracking:

```html
<body data-linkgravity-auto data-api-url="https://api.linkgravity.io">

  <!-- Regular link -->
  <a href="https://yourapp.com/product/123" data-linkgravity-id="lg_abc123">
    View Product
  </a>

  <!-- App Store link -->
  <a href="https://apps.apple.com/app/yourapp" data-linkgravity-id="lg_xyz789">
    Download on App Store
  </a>

</body>
```

That's it! The SDK will automatically track clicks and collect fingerprints.

### 3. Manual Tracking (Optional)

For more control, use the manual API:

```html
<script src="https://cdn.linkgravity.io/web-sdk/v1/linkgravity-web-sdk.js"></script>
<script>
  // Initialize SDK
  const linkGravity = new LinkGravityWeb({
    apiUrl: 'https://api.linkgravity.io',
    debug: true, // Enable console logging
    enableCanvasFingerprint: true,
    enableWebGLFingerprint: true,
    enableFontDetection: false, // Disabled for privacy by default
  });

  // Track specific link click
  document.getElementById('myLink').addEventListener('click', async (e) => {
    try {
      await linkGravity.trackClick('lg_abc123', {
        campaign: 'summer-sale',
        source: 'homepage',
      });
    } catch (error) {
      console.error('Tracking failed:', error);
    }
  });

  // Or collect fingerprint without tracking
  const fingerprint = linkGravity.collectFingerprint();
  console.log('Browser fingerprint:', fingerprint);
</script>
```

## Configuration Options

```javascript
const linkGravity = new LinkGravityWeb({
  // API endpoint (required)
  apiUrl: 'https://api.linkgravity.io',

  // Enable debug logging
  debug: false,

  // Enable canvas fingerprinting (privacy-aware)
  enableCanvasFingerprint: true,

  // Enable WebGL fingerprinting
  enableWebGLFingerprint: true,

  // Enable font detection (disabled by default for privacy)
  enableFontDetection: false,
});
```

## Collected Fingerprint Data

The SDK collects the following browser signals:

### Always Collected (Privacy-Safe)
- **User-Agent**: Real browser User-Agent string
- **Platform**: e.g., "Win32", "MacIntel", "iPhone"
- **Vendor**: Browser vendor
- **Language**: Browser language and preferences
- **Hardware**: CPU cores, device memory (if available)
- **Screen**: Resolution, color depth, viewport size
- **Timezone**: Timezone and offset
- **Connection**: Network type and speed (if available)
- **Cookies**: Cookie support
- **Do Not Track**: DNT setting

### Optional (Privacy-Aware)
- **Canvas Fingerprint**: Hashed canvas rendering signature
- **WebGL**: Graphics card vendor and renderer
- **Fonts**: Detected installed fonts

## Privacy & GDPR Compliance

The LinkGravity Web SDK is designed with privacy in mind:

✅ **No PII Collection**: No personal information, emails, or names
✅ **No Cross-Site Tracking**: Only tracks LinkGravity links
✅ **Respects DNT**: Do Not Track setting is honored
✅ **Optional Fingerprinting**: Advanced fingerprinting is opt-in
✅ **GDPR Compliant**: Can be configured for GDPR compliance
✅ **Transparent**: Open source, inspect the code

### GDPR Recommendations

1. **Inform Users**: Update your privacy policy to mention link tracking
2. **Obtain Consent**: If required in your jurisdiction, get user consent
3. **Minimal Data**: Disable optional fingerprinting for stricter privacy:

```javascript
const linkGravity = new LinkGravityWeb({
  apiUrl: 'https://api.linkgravity.io',
  enableCanvasFingerprint: false,
  enableWebGLFingerprint: false,
  enableFontDetection: false,
});
```

## API Reference

### `new LinkGravityWeb(config)`

Create a new SDK instance.

**Parameters:**
- `config.apiUrl` (string, required): API endpoint URL
- `config.debug` (boolean): Enable debug logging
- `config.enableCanvasFingerprint` (boolean): Enable canvas fingerprinting
- `config.enableWebGLFingerprint` (boolean): Enable WebGL fingerprinting
- `config.enableFontDetection` (boolean): Enable font detection

**Returns:** LinkGravityWeb instance

### `collectFingerprint()`

Collect browser fingerprint without sending to API.

**Returns:** Object with fingerprint data

```javascript
const fingerprint = linkGravity.collectFingerprint();
console.log(fingerprint);
// {
//   userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)...",
//   platform: "iPhone",
//   timezone: "America/Los_Angeles",
//   screenResolution: "390x844",
//   ...
// }
```

### `trackClick(linkId, additionalData)`

Track link click and send fingerprint to backend.

**Parameters:**
- `linkId` (string, required): LinkGravity link ID (e.g., "lg_abc123")
- `additionalData` (object, optional): Additional tracking data

**Returns:** Promise with API response

```javascript
await linkGravity.trackClick('lg_abc123', {
  campaign: 'summer-sale',
  medium: 'email',
  source: 'newsletter',
});
```

### `autoTrack()`

Automatically track all links with `data-linkgravity-id` attribute.

```javascript
linkGravity.autoTrack();
```

## Examples

### Example 1: Simple Download Button

```html
<!DOCTYPE html>
<html>
<head>
  <title>Download Our App</title>
</head>
<body data-linkgravity-auto data-api-url="https://api.linkgravity.io">

  <h1>Get Our Mobile App</h1>

  <a href="https://apps.apple.com/app/yourapp"
     data-linkgravity-id="lg_homepage_ios"
     class="download-btn">
    📱 Download for iOS
  </a>

  <a href="https://play.google.com/store/apps/details?id=com.yourapp"
     data-linkgravity-id="lg_homepage_android"
     class="download-btn">
    🤖 Download for Android
  </a>

  <script src="https://cdn.linkgravity.io/web-sdk/v1/linkgravity-web-sdk.js"></script>
</body>
</html>
```

### Example 2: Product Landing Page

```html
<!DOCTYPE html>
<html>
<head>
  <title>Premium Widget - Now on Mobile!</title>
</head>
<body>

  <div class="product-hero">
    <h1>Premium Widget</h1>
    <p>Download our app for exclusive mobile-only deals!</p>

    <button id="cta-button">Get 50% Off in App →</button>
  </div>

  <script src="https://cdn.linkgravity.io/web-sdk/v1/linkgravity-web-sdk.js"></script>
  <script>
    const linkGravity = new LinkGravityWeb({
      apiUrl: 'https://api.linkgravity.io',
      debug: false,
      enableCanvasFingerprint: true,
      enableWebGLFingerprint: true,
    });

    document.getElementById('cta-button').addEventListener('click', async () => {
      // Track click
      await linkGravity.trackClick('lg_product_premium_widget', {
        product: 'premium-widget',
        discount: '50-percent',
        cta: 'hero-button',
      });

      // Redirect to app store
      const isIOS = /iPhone|iPad|iPod/.test(navigator.userAgent);
      const appStoreUrl = isIOS
        ? 'https://apps.apple.com/app/yourapp'
        : 'https://play.google.com/store/apps/details?id=com.yourapp';

      window.location.href = appStoreUrl;
    });
  </script>
</body>
</html>
```

### Example 3: Email Campaign

```html
<!-- email-template.html -->
<!DOCTYPE html>
<html>
<body>
  <h1>Summer Sale - 70% Off!</h1>
  <p>Open our app for exclusive summer deals 🌞</p>

  <!-- This link opens in browser when user clicks from email -->
  <a href="https://yourwebsite.com/summer-sale"
     style="padding: 12px 24px; background: #007AFF; color: white;">
    Open App & Save 70%
  </a>
</body>
</html>
```

```html
<!-- yourwebsite.com/summer-sale -->
<!DOCTYPE html>
<html>
<head>
  <title>Summer Sale - Download App</title>
  <meta http-equiv="refresh" content="0; url=https://apps.apple.com/app/yourapp">
</head>
<body data-linkgravity-auto data-api-url="https://api.linkgravity.io">

  <h1>Redirecting to App Store...</h1>
  <p>If you're not redirected, <a href="https://apps.apple.com/app/yourapp"
     data-linkgravity-id="lg_email_summer_sale">click here</a></p>

  <script src="https://cdn.linkgravity.io/web-sdk/v1/linkgravity-web-sdk.js"></script>
</body>
</html>
```

## Browser Support

- ✅ Chrome 60+
- ✅ Firefox 55+
- ✅ Safari 11+
- ✅ Edge 79+
- ✅ Mobile Safari (iOS 11+)
- ✅ Chrome for Android

## Troubleshooting

### Fingerprint not being sent

**Check:**
1. Is `data-linkgravity-id` attribute present on the link?
2. Is `data-api-url` specified?
3. Check browser console for errors (enable `debug: true`)
4. Verify CORS is enabled on your API endpoint

### CORS errors

Make sure your API endpoint allows requests from your website domain:

```http
Access-Control-Allow-Origin: https://yourwebsite.com
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

### Click tracking not working

**Verify:**
1. SDK script is loaded before `DOMContentLoaded`
2. Link has `data-linkgravity-id` attribute
3. `autoTrack()` was called or `data-linkgravity-auto` is present
4. API endpoint is reachable

## Performance

- **Bundle Size**: ~5KB minified (gzipped)
- **Execution Time**: <10ms fingerprint collection
- **Network**: Single POST request per click (~2-5KB payload)
- **No Impact on Page Load**: Async, non-blocking

## Security

- **HTTPS Only**: All API requests use HTTPS
- **No Sensitive Data**: No passwords, credit cards, or PII
- **XSS Protection**: All user input is sanitized
- **CSP Compatible**: Works with Content Security Policy

## Support

- **Documentation**: https://docs.linkgravity.io/web-sdk
- **GitHub**: https://github.com/linkgravity/flutter-sdk
- **Email**: support@linkgravity.io

## License

MIT License - See LICENSE file for details

---

**Made with ❤️ by the LinkGravity Team**
