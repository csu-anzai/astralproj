const io = require("socket.io"),
			fs = require("fs"),
			err = require("./../err");
let then = require("./../then");
module.exports = (env, express, reducer) => {
	let server;
	then = then.bind(this, reducer);
	if (env.server.https) {
		server = require("https").createServer({
			key: fs.readFileSync(`${__dirname}/../constants/${env.server.keyFile}`),
			cert: fs.readFileSync(`${__dirname}/../constants/${env.server.certFile}`)
		}, express);
	} else {
		server = require("http").createServer(express);
	};
	server.listen(env.ws.port);
	const sockets = io(server);
	sockets.on("connection", connection => {
		reducer.dispatch({
			type: "query",
			data: {
				query: "newConnection",
				values: [
					3,
					connection.id
				]
			}
		}).then(then).catch(err);
		connection.on("message", action => {
			reducer.dispatch(action).then(then).catch(err);
		});
		connection.on("disconnect", action => {
			reducer.dispatch({
				type: "query",
				data: {
					query: "disconnectConnection",
					values: [
						connection.id,
						"NULL"
					]
				}
			}).then(then).catch(err);
		});
	});
	return sockets;
}
