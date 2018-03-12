const merge = require('webpack-merge');
const common = require('./webpack.common.js');
const webpack = require('webpack');
module.exports = merge(common, {
	entry: [
		'webpack-dev-server/client?http://0.0.0.0:8080/',
    'webpack/hot/only-dev-server',
    'react-hot-loader/patch',
    __dirname + "/src/client/index.jsx"
	],
	devtool: 'inline-source-map',
	devServer: {
		contentBase: __dirname + "/build",
		hot: true,
		inline: true,
		noInfo:true
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