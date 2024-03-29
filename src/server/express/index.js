const Express = require("express"),
			Helmet = require("helmet"),
			parser = require("body-parser"),
			expressFileupload = require("express-fileupload"),
			uploadCompanies = require("./uploadCompanies.js"),
			exportLeads = require("./exportLeads.js"),
			channels = require("./channels.js"),
			uploadCompaniesByChannel = require("./uploadCompaniesByChannel.js");


let err = require("./../err"),
		then = require("./../then");
module.exports = (env, reducer) => {
	then = then.bind(this, reducer);
	err = err.bind(this, reducer);
	const express = Express();
	express.use((req, res, next) => {
	  res.header('Access-Control-Allow-Origin', "*");
	  res.header('Access-Control-Allow-Headers', "*");
	  next();
	})
	express.use(Helmet());
	express.use(parser.urlencoded({extended: false}));
	express.use(expressFileupload());
	express.listen(env.express.port, () => {
		console.log(`Сервер запущен на порту ${env.express.port}`)
	});
	express.post("/api/", (req, res) => {
		if(req.body.data){
			let data = req.body.data;
			typeof data == "string" && (data = JSON.parse(data));
			reducer.dispatch(data).then(then).catch(err);
			res.send(true);
		}
		res.send(false);
	});
	express.get("/api/exportLeads", exportLeads);
	express.post("/api/uploadCompanies", uploadCompanies);
	express.post("/api/uploadCompaniesByChannel", uploadCompaniesByChannel);
	express.get("/api/channels", channels);
	express.post("/api/zadarma", (req, res) => {
		reducer.modules.log.writeLog("zadarma", {
			type: "in",
			data: req.body
		});
		const event = req.body.event;
		let internal = req.body.internal,
				destination = req.body.destination,
				disposition = req.body.disposition,
				dispositionType = 0;
		if(disposition){
			switch(disposition){
				case "answered":
					dispositionType = 46;
					break;
				case "busy":
					dispositionType = 47;
					break;
				case "cancel":
					dispositionType = 48;
					break;
				case "no answer":
					dispositionType = 49;
					break;
				case "failed":
					dispositionType = 50;
					break;
				case "no money":
					dispositionType = 51;
					break;
				case "unallocated number":
					dispositionType = 52;
					break;
				case "no limit":
					dispositionType = 53;
					break;
				case "no day limit":
					dispositionType = 38;
					break;
				case "line limit":
					dispositionType = 40;
					break;
				case "no money, no limit":
					dispositionType = 41;
					break;
			}
		}
		switch(event){
			case "NOTIFY_START":
				break;
			case "NOTIFY_INTERNAL":
				break;
			case "NOTIFY_END":
				break;
			case "NOTIFY_ANSWER":
				reducer.dispatch({
					type: "query",
					data: {
						query: "setCallStatus",
						values: [
							null,
							req.body.pbx_call_id,
							null,
							39
						]
					}
				}).then(then).catch(err);
				break;
			case "NOTIFY_OUT_START":
				reducer.dispatch({
					type: "query",
					data: {
						query: "setCallStatus",
						values: [
							internal.length > 3 ? destination : internal,
							req.body.pbx_call_id,
							null,
							34
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
							null,
							req.body.pbx_call_id,
							req.body.call_id_with_rec,
							dispositionType
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
		reducer.modules.log.writeLog("zadarma", {
			type: "echo",
			data: req.query.zd_echo
		});
	});
	express.use(Express.static(__dirname + env.express.staticPath));
	return express;
}
