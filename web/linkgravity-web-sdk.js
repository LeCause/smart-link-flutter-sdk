/**
 * LinkGravity Web SDK
 *
 * Collects web fingerprint and sends click tracking to LinkGravity backend
 * for improved web-to-app attribution matching
 *
 * @version 1.0.0
 * @license MIT
 */

(function(window) {
  'use strict';

  /**
   * LinkGravity Web SDK Class
   */
  class LinkGravityWeb {
    constructor(config) {
      this.config = {
        apiUrl: config.apiUrl || 'https://api.linkgravity.io',
        debug: config.debug || false,
        ...config
      };

      if (this.config.debug) {
        console.log('[LinkGravity] Initialized with config:', this.config);
      }
    }

    /**
     * Collect comprehensive web fingerprint
     * @returns {Object} Web fingerprint data
     */
    collectFingerprint() {
      const fingerprint = {
        // User Agent (REAL from browser)
        userAgent: navigator.userAgent,

        // Platform info
        platform: navigator.platform,
        vendor: navigator.vendor || '',
        language: navigator.language,
        languages: navigator.languages ? Array.from(navigator.languages) : [],

        // Hardware info
        hardwareConcurrency: navigator.hardwareConcurrency || null,
        deviceMemory: navigator.deviceMemory || null,
        maxTouchPoints: navigator.maxTouchPoints || 0,

        // Screen info
        screenResolution: `${screen.width}x${screen.height}`,
        screenColorDepth: screen.colorDepth,
        screenPixelDepth: screen.pixelDepth || screen.colorDepth,
        availableScreenResolution: `${screen.availWidth}x${screen.availHeight}`,

        // Timezone
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        timezoneOffset: new Date().getTimezoneOffset(),

        // Viewport
        viewportSize: `${window.innerWidth}x${window.innerHeight}`,

        // Connection (if available)
        connection: this._getConnectionInfo(),

        // Additional signals
        cookieEnabled: navigator.cookieEnabled,
        doNotTrack: navigator.doNotTrack || null,

        // Timestamp
        timestamp: Date.now(),
      };

      // Add canvas fingerprint (optional, privacy-aware)
      if (this.config.enableCanvasFingerprint) {
        fingerprint.canvasFingerprint = this._getCanvasFingerprint();
      }

      // Add WebGL info (optional)
      if (this.config.enableWebGLFingerprint) {
        fingerprint.webgl = this._getWebGLInfo();
      }

      // Add installed fonts (optional, privacy-aware)
      if (this.config.enableFontDetection) {
        fingerprint.fonts = this._getInstalledFonts();
      }

      if (this.config.debug) {
        console.log('[LinkGravity] Fingerprint collected:', fingerprint);
      }

      return fingerprint;
    }

    /**
     * Track link click and send fingerprint to backend
     * @param {string} linkId - LinkGravity link ID
     * @param {Object} additionalData - Additional tracking data
     * @returns {Promise} API response
     */
    async trackClick(linkId, additionalData = {}) {
      const fingerprint = this.collectFingerprint();

      const payload = {
        linkId,
        fingerprint,
        timestamp: Date.now(),
        ...additionalData
      };

      if (this.config.debug) {
        console.log('[LinkGravity] Tracking click:', payload);
      }

      try {
        const response = await fetch(`${this.config.apiUrl}/v1/clicks`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        if (this.config.debug) {
          console.log('[LinkGravity] Click tracked successfully:', data);
        }

        return data;
      } catch (error) {
        console.error('[LinkGravity] Error tracking click:', error);
        throw error;
      }
    }

    /**
     * Auto-track all LinkGravity links on page
     * Adds click event listeners to all links with data-linkgravity-id attribute
     */
    autoTrack() {
      const links = document.querySelectorAll('[data-linkgravity-id]');

      if (this.config.debug) {
        console.log(`[LinkGravity] Auto-tracking ${links.length} links`);
      }

      links.forEach(link => {
        const linkId = link.getAttribute('data-linkgravity-id');

        link.addEventListener('click', async (event) => {
          try {
            await this.trackClick(linkId, {
              clickedUrl: link.href,
              clickedText: link.textContent.trim(),
            });
          } catch (error) {
            // Don't prevent navigation on error
            console.error('[LinkGravity] Click tracking failed:', error);
          }
        });
      });
    }

    /**
     * Get network connection info
     * @private
     */
    _getConnectionInfo() {
      const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

      if (!connection) return null;

      return {
        effectiveType: connection.effectiveType || null,
        downlink: connection.downlink || null,
        rtt: connection.rtt || null,
        saveData: connection.saveData || false,
      };
    }

    /**
     * Generate canvas fingerprint
     * @private
     */
    _getCanvasFingerprint() {
      try {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');

        if (!ctx) return null;

        // Draw text
        const text = 'LinkGravity fingerprint 🔗';
        ctx.textBaseline = 'top';
        ctx.font = '14px "Arial"';
        ctx.textBaseline = 'alphabetic';
        ctx.fillStyle = '#f60';
        ctx.fillRect(125, 1, 62, 20);
        ctx.fillStyle = '#069';
        ctx.fillText(text, 2, 15);
        ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
        ctx.fillText(text, 4, 17);

        // Get canvas data
        const dataURL = canvas.toDataURL();

        // Hash it (simple hash for fingerprinting)
        return this._simpleHash(dataURL);
      } catch (e) {
        return null;
      }
    }

    /**
     * Get WebGL renderer info
     * @private
     */
    _getWebGLInfo() {
      try {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');

        if (!gl) return null;

        const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');

        return {
          vendor: debugInfo ? gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL) : gl.getParameter(gl.VENDOR),
          renderer: debugInfo ? gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER),
        };
      } catch (e) {
        return null;
      }
    }

    /**
     * Detect installed fonts
     * @private
     */
    _getInstalledFonts() {
      const baseFonts = ['monospace', 'sans-serif', 'serif'];
      const testFonts = [
        'Arial', 'Verdana', 'Times New Roman', 'Courier New',
        'Georgia', 'Palatino', 'Garamond', 'Bookman',
        'Comic Sans MS', 'Trebuchet MS', 'Impact'
      ];

      const installedFonts = [];

      // Simple font detection
      testFonts.forEach(font => {
        if (this._isFontAvailable(font, baseFonts)) {
          installedFonts.push(font);
        }
      });

      return installedFonts;
    }

    /**
     * Check if font is available
     * @private
     */
    _isFontAvailable(fontName, baseFonts) {
      const testString = 'mmmmmmmmmmlli';
      const testSize = '72px';
      const canvas = document.createElement('canvas');
      const context = canvas.getContext('2d');

      context.font = testSize + ' ' + baseFonts[0];
      const baselineSize = context.measureText(testString).width;

      context.font = testSize + ' ' + fontName + ', ' + baseFonts[0];
      const newSize = context.measureText(testString).width;

      return newSize !== baselineSize;
    }

    /**
     * Simple hash function
     * @private
     */
    _simpleHash(str) {
      let hash = 0;
      for (let i = 0; i < str.length; i++) {
        const char = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash; // Convert to 32-bit integer
      }
      return hash.toString(36);
    }
  }

  // Expose to window
  window.LinkGravityWeb = LinkGravityWeb;

  // Auto-initialize if data-linkgravity-auto attribute exists
  if (document.querySelector('[data-linkgravity-auto]')) {
    document.addEventListener('DOMContentLoaded', function() {
      const autoElement = document.querySelector('[data-linkgravity-auto]');
      const apiUrl = autoElement.getAttribute('data-api-url');
      const debug = autoElement.hasAttribute('data-debug');

      const sdk = new LinkGravityWeb({
        apiUrl,
        debug,
        enableCanvasFingerprint: true,
        enableWebGLFingerprint: true,
        enableFontDetection: false, // Disabled by default for privacy
      });

      sdk.autoTrack();

      // Expose to window for manual access
      window.linkGravitySDK = sdk;
    });
  }

})(window);
