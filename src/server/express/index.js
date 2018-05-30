const Express = require("express"),
			Helmet = require("helmet"),
			parser = require("body-parser"),
			err = require("./../err");
let then = require("./../then");
module.exports = (env, reducer) => {
	then = then.bind(this, reducer);
	const express = Express();
	express.use(Helmet());
	express.use(parser.urlencoded({extended: false}));
	express.listen(env.express.port);
	express.post("/api/", (req, res) => {
		if(req.body.data){
			let data = req.body.data;
			typeof data == "string" && (data = JSON.parse(data));
			reducer.dispatch(data).then(then).catch(err);
			res.send(true);
		}
		res.send(false);
	});
	express.post("/api/zadarma", (req, res) => {
		const event = req.body.event;
		let from = req.body.internal.length == 3 ? req.body.internal : req.body.destination,
				to = req.body.internal.length == 3 ? req.body.destination : req.body.internal;
		switch(event){
			case "NOTIFY_START":
				break;
			case "NOTIFY_INTERNAL":
				break;
			case "NOTIFY_ANSWER":
				reducer.dispatch({
					type: "query",
					data: {
						query: "setCallStatus",
						values: [
							from,
							to,
							39,
							req.body.pbx_call_id,
							null
						]
					}
				}).then(then).catch(err);
				break;
			case "NOTIFY_END":
				break;
			case "NOTIFY_OUT_START":
				reducer.dispatch({
					type: "query",
					data: {
						query: "setCallStatus",
						values: [
							from,
							to,
							req.body.internal.length == 3 ? 38 : 34,
							req.body.pbx_call_id,
							null
						]
					}
				}).then(then).catch(err);
				break;
			case "NOTIFY_OUT_END":
				reducer.dispatch({
					type: "query",
					data: {
						query: "setCallStatus",
						values: [
							from,
							to,
							req.body.internal.length == 3 ? 41 : 40,
							req.body.pbx_call_id,
							req.body.call_id_with_rec
						]
					}
				}).then(then).catch(err);
				break;
			case "NOTIFY_RECORD":
				reducer.dispatch({
					type: "query",
					data: {
						query: "setCallRecord",
						values: [
							req.body.call_id_with_rec,
							req.body.pbx_call_id
						]
					}
				}).then(then).catch(err);
				break;
		}
	});
	express.get("/api/zadarma", (req, res) => {
		res.send(req.query.zd_echo);	
	});
	express.use(Express.static(__dirname + env.express.staticPath));
	return express;
}