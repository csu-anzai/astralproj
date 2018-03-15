module.exports = modules => (resolve, reject, data) => {
	modules.mysql.query({
		sql: `SELECT ${data.query}(${data.values.map(item => "?").join(",")}) AS a`,
		values: data.values
	}, (err, responce) => {
		err ? reject(err) : resolve(responce);
	});
}