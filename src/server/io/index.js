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
	const sockets = io(server);
	sockets.on("message", action => {
		reducer.dispatch(action).then(then).catch(err);
	});
	return sockets;
}
