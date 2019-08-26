module.exports = modules => (resolve, reject, data) => {
	modules.log.writeLog("db", {
		type: "query",
		data
	});

	modules.mysql.query(
		`SET @responce = JSON_ARRAY(); CALL ${data.query}(${modules.mysql.escape(data.values)}, @responce); SELECT @responce AS a`,
		(err, responce) => {
			console.log("VALUES: ", data.values);
			console.log("ERROR: ", err);
			console.log("RESPONSE: ", responce);
			err ? reject(err) : resolve(responce);
			modules.log.writeLog("db", {
				query: data.query,
				responce
			});
		}
	);
}
