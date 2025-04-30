// craco.config.js
// Webpack konfiguratsiooni täiendus Node.js moodulite polyfill'ide lisamiseks
const webpack = require('webpack');

module.exports = {
  webpack: {
    configure: {
      resolve: {
        fallback: {
          url: require.resolve('url/'),
          http: require.resolve('stream-http'),
          https: require.resolve('https-browserify'),
          util: require.resolve('util/'),
          zlib: require.resolve('browserify-zlib'),
          stream: require.resolve('stream-browserify'),
          assert: require.resolve('assert/'),
          buffer: require.resolve('buffer/'),
          process: require.resolve('process/browser'),
        }
      }
    },
    plugins: [
      // Lisa uued Node.js/Browserify polyfill-id
      new webpack.ProvidePlugin({
        process: 'process/browser',
        Buffer: ['buffer', 'Buffer'],
      }),
    ]
  }
};