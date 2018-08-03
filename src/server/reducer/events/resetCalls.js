module.exports = modules => (resolve, reject, data) => {
	modules.reducer.dispatch({
		type: "query",
		data: {
			query: "resetCalls",
			values: [

			]
		}
	}).then(modules.then).catch(modules.err);
}