const ExtractTextPlugin = require("extract-text-webpack-plugin");
const path = require('path');
const webpack = require('webpack');
const cssnext = require('postcss-cssnext');
const short = require('postcss-short');
const _import = require('postcss-easy-import');
// const assets = require('postcss-assets';
// const reporter = require('postcss-reporter';

const browsers = [
  'ie >= 11',
  'edge > 13',
  'ff >= 54',
  'chrome >= 59',
  'safari >= 9',
  'ios >= 9',
  'android >= 5',
  'ChromeAndroid >= 59'
];

module.exports = {
  context: path.resolve(__dirname, './front'),
  entry: {
    vendor: ['babel-polyfill', 'lodash', 'riot'],
    app: ['./scripts/index.js'],
    login: ['./scripts/login.js']
  },

  output: {
    path: path.resolve(__dirname, './public/javascripts'),
    filename: '[name].bundle.js',
    publicPath: '/' // devServerのパス
  },

  module: {
    rules: [
      {
        test: /\.tag$/,
        enforce: "pre",
        exclude: [/node_modules/],
        use: [
          { loader: 'riotjs-loader',
            query: {
              template: 'pug'
            }
          }
        ]
      }, {
        test: /\.(js|tag)$/,
        exclude: [/node_modules/],
        use: [{
          loader: 'babel-loader',
          options: {
            presets: [
              "es2015-riot",
              "stage-0"
            ]
          }
        }]
      }, {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
            fallback: 'style-loader',
            use: [
              {
                loader: 'css-loader',
                options: {
                  modules: false,
                  sourceMap: true,
                  importLoaders: 1
                }
              },
              {
                loader: 'postcss-loader',
                options: {
                  plugins: (loader) => [
                    _import({
                      glob: true
                    }),
                    short,
                    cssnext({
                      browsers,
                      features: {
                        autoprefixer: {remove: false}
                      }
                    })
                  ]
                }
              }
            ]
          })
      },
      {
        test: /\.(abi|bin)$/,
        use: 'raw-loader'
      }
    ]
  },
  plugins: [
    new webpack.NoEmitOnErrorsPlugin(),
    new webpack.DefinePlugin({
      'process.env': {
        'NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'local')
      }
    }),
    new webpack.ProvidePlugin({ riot: 'riot' }),
    new ExtractTextPlugin({
      filename: '[name].css',
      allChunks: true
    })
  ],
};

