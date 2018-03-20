module.exports = {
	entry: __dirname + "/src/client/index.jsx",
	output: {
		filename: "bundle.js",
		chunkFilename: '[id].[hash].chunk.js',
		path: __dirname + "/build"
	},
	resolve: {
		extensions: [".js", ".jsx"]
	}
}