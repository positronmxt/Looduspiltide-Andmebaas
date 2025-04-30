// webpack.config.js
module.exports = {
  resolve: {
    fallback: {
      "http": false,
      "https": false,
      "url": false,
      "zlib": false,
      "stream": false,
      "util": false,
      "assert": false
    }
  }
};