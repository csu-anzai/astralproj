const Express = require("express"),
			Helmet = require("helmet"),
			parser = require("body-parser");
			err = require("./../err");
let then = require("./../then");
module.exports = (env, reducer) => {
	then = then.bind(this, reducer);
	const express = Express();
	express.use(Helmet());
	express.use(parser.urlencoded({extended: false}));
	express.listen(env.express.port);
	express.post("/api/", (req, res) => {
		let data = JSON.parse(req.body.data);
		reducer.dispatch(data).then(then).catch(err);
	});
	return express;
}