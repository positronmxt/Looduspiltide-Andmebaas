// browserPolyfill.js
// See fail konfigureerib vajalikud Node.js polyfill'id Webpacki jaoks
window.process = require('process');
window.Buffer = require('buffer').Buffer;