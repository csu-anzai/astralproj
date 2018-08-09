const io = require("socket.io"),
			fs = require("fs");
let then = require("./../then"),
		err = require("./../err");
module.exports = (env, express, reducer) => {
	let server;
	then = then.bind(this, reducer);
	err = err.bind(this, reducer);
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
		reducer.modules.log.writeLog("ws", `установленно соединение: ${connection.id}`);
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
			reducer.modules.log.writeLog("ws", {
				type: "client",
				data: action
			});
			reducer.dispatch(action).then(then).catch(err);
		});
		connection.on("disconnect", action => {
			reducer.modules.log.writeLog("ws", `разорвано соединение: ${connection.id}`);
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
