module.exports = {
	entry: {
		'build/front/front': __dirname + "/src/client/index.jsx",
		'build/back/back': __dirname + "/src/server/index.js"
	},
	output: {
		filename: "[name].bundle.js",
		chunkFilename: '[name].[id].[hash].chunk.js',
		path: __dirname
	},
	target: "node",
	resolve: {
		extensions: [".js", ".jsx"]
	}
}