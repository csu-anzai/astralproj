module.exports = modules => (resolve, reject, data) => {
	modules.log.writeLog("db", {
		type: "query",
		data
	});
	modules.mysql.query(
		`SET @responce = JSON_ARRAY(); CALL ${data.query}("${data.values.join("\",\"")}", @responce); SELECT @responce AS a`,
		(err, responce) => {
			err ? reject(err) : resolve(responce);
			modules.log.writeLog("db", {
				query: data.query,
				responce
			});
		}
	);
}