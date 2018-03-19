const mysql = require('mysql');
module.exports = env => {
	const connection = mysql.createConnection(env.mysql);
	return connection;
}