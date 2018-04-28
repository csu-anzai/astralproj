const env = require('../env.json'),
			reducer = new (require('./reducer/')),
			express = require('./express')(env, reducer),
			io = require('./io')(env, express, reducer),
			nodemailer = require('./nodemailer')(env),
			mysql = require('./mysql')(env),
			imap = require('./imap')(env, reducer),
			err = require('./err');
let 	then = require('./then');
then = then.bind(this, reducer);
reducer.initEvents({
	io,
	express,
	nodemailer,
	mysql,
	reducer,
	env,
	then,
	err
});
reducer.dispatch({
	type: "query",
	data: {
		query: "disconnectAll",
		values: []
	}
});
setTimeout(() => {
	let nowDate = new Date(),
			nowHours = nowDate.getHours(),
			nowMinutes = nowDate.getMinutes(),
			nowSeconds = nowDate.getSeconds(),
			nowMilleseconds = nowDate.getMilliseconds(),
			envMilliseconds = (env.check.hours * 60 * 60 * 1000) + (env.check.minutes * 60 * 1000) + (env.check.seconds * 1000) + env.check.milliseconds,
			timeoutMilliseconds = 0;
	nowMilleseconds = (nowHours * 60 * 60 * 1000) + (nowMinutes * 60 * 1000) + (nowSeconds * 1000) + nowMilleseconds;
	if(nowMilleseconds < envMilliseconds){
		timeoutMilliseconds = envMilliseconds - nowMilleseconds;
	} else {
		timeoutMilliseconds = 86400000 - nowMilleseconds + envMilliseconds;
	}
	setTimeout(() => {
		reducer.dispatch({
			type: "checkCompaniesStatus",
			data: [

			]
		}).then(responce => {
			setInterval(() => {
				reducer.dispatch({
					type: "checkCompaniesStatus",
					data: [

					]
				}).then(then).catch(err);
			}, 86400000);
			then(responce);
		}).catch(err);
	}, timeoutMilliseconds);
});
