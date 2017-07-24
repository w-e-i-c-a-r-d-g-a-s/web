const webpack = require('webpack');
const path = require('path');
const base = require('./webpack.config.base.js');

const config = Object.create(base);

config.devtool = "cheap-module-source-map";

config.devServer = {
  contentBase: path.resolve(__dirname, './app'),
  port: 9000,
  stats: {
    assets: true,
    cached: false,
    cachedAssets: false,
    children: false,
    chunks: false,
    chunkModules: false,
    chunkOrigins: false,
    chunksSort: "field",
    colors: true,
    hash: false,
    // 不要なchunkモジュールのログを消している
    maxModules: 0,
    // これだと消えない・・bug?
    modules: false,
    performance: true,
    publicPath: false
  }
};

config.plugins.unshift(
  new webpack.optimize.CommonsChunkPlugin({
    name: 'vendor',
    minChunks: Infinity
  }),
  new webpack.BannerPlugin({
    banner: "hash:[hash], chunkhash:[chunkhash], name:[name], filebase:[filebase], query:[query], file:[file]"
  })
);

module.exports = config;
