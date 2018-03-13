module.exports = {
	entry: __dirname + "/src/client/index.jsx",
	output: {
		filename: "[name].bundle.js",
		path: __dirname + "/build"
	},
	resolve: {
		extensions: [".js", ".jsx"]
	}
}