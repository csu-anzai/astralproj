module.exports = (reducer, data) => {
	reducer.modules.log.writeLog("error", data);
}