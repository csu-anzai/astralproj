const merge = require('webpack-merge');
const common = require('./webpack.common.js');
const webpack = require('webpack');
module.exports = merge(common, {
	entry: {
		devserver: 'webpack-dev-server/client?http://0.0.0.0:8080/',
    webpackhot: 'webpack/hot/only-dev-server',
    reacthot:'react-hot-loader/patch',
    'front/front': __dirname + "/src/client/index.jsx"
	},
	devtool: 'inline-source-map',
	devServer: {
		contentBase: __dirname + "/build/",
		hot: true,
		inline: true
	},
	module: {
		rules: [
			{
				test: /\.(js|jsx)$/,
				loader: "babel-loader",
				options: {
					cacheDirectory: true,
					plugins: ['react-hot-loader/babel']
				}
			}
		]
	},
	mode: "development",
	plugins: [
		new webpack.HotModuleReplacementPlugin()
	]
});