// src/polyfills.js
// Node.js moodulite polyfill'id React keskkonna jaoks

// Põhilised Node.js moodulid, mida axios vajab
global.Buffer = require('buffer').Buffer;
global.process = require('process');

// HTTP ja HTTPS polyfill'id
window.http = require('stream-http');
window.https = require('https-browserify');
window.url = require('url/');
window.util = require('util/');
window.stream = require('stream-browserify');
window.zlib = require('browserify-zlib');
window.assert = require('assert/');

// Lihtne vaikimisi implementatsioon 'http' ja 'https' moodulitele
if (typeof window.http === 'undefined') {
  window.http = {
    request: function() {
      console.warn('HTTP mooduli simulatsioon - tegelikku HTTP päringut ei tehta');
      return { end: function() {} };
    }
  };
}

if (typeof window.https === 'undefined') {
  window.https = {
    request: function() {
      console.warn('HTTPS mooduli simulatsioon - tegelikku HTTPS päringut ei tehta');
      return { end: function() {} };
    }
  };
}

console.log('Node.js moodulite polyfill\'id on laaditud');