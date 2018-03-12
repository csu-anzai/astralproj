const merge = require('webpack-merge');
const common = require('./webpack.common.js');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
module.exports = merge(common, {
	plugins: [
		new UglifyJSPlugin()
	],
	module: {
		rules: [
			{
				test: /\.(js|jsx)$/,
				loader: "babel-loader"
			}
		]
	},
	mode: "production"
});