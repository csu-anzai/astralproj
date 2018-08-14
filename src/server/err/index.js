module.exports = (reducer, data) => {
	reducer.modules.log.writeLog("errors", data);
}