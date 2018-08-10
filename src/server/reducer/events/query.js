module.exports = modules => (resolve, reject, data) => {
	modules.log.writeLog("db", {
		type: "query",
		data
	});
	modules.mysql.query({
		sql: `SELECT ${data.priority ? "HIGH_PRIORITY" : ""} ${data.query}(${data.values.map(item => "?").join(",")}) AS a`,
		values: data.values
	}, (err, responce) => {
		err ? reject(err) : resolve(responce);
		modules.log.writeLog("db", {
			type: "responce",
			data: {
				query: data.query,
				responce
			}
		});
	});
}