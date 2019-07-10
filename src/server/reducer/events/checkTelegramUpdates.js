module.exports = modules => (resolve, reject, data) => {
	modules.telegram.getUpdates(msg => {
		modules.log.writeLog("telegram", msg);
		modules.reducer.dispatch({
			type: "query",
			data: {
				query: "confirmTelegram",
				values: [
					msg.chat.id
				]
			}
		}).then(modules.then).catch(modules.err);
	});
}