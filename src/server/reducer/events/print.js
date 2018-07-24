module.exports = modules => (resolve, reject, data) => {
	console.log(data.message);
	data.hasOwnProperty("telegram") && data.telegram == 1 && modules.reducer.dispatch({
		type: "query",
		data: {
			query: "sendToTelegram",
			values: [data.message]
		}
	}).then(resolve).catch(reject);
}