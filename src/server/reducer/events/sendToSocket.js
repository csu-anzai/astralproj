module.exports = modules => (resolve, reject, data) => {
	modules.io.to(data.socketID).send(data.data);
	modules.log.writeLog("ws", {
		type: "server",
		data: data.data
	});
}