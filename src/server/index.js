const env = require('../env.json'),
			reducer = new (require('./reducer/')),
			express = require('./express')(env, reducer),
			io = require('./io')(env, express, reducer),
			nodemailer = require('./nodemailer')(env),
			mysql = require('./mysql')(env),
			imap = require('./imap')(env, reducer),
			telegram = require('./telegram')(env, reducer),
			err = require('./err'),
		 	then = require('./then').bind(this, reducer),
		 	nowDate = new Date(),
			nowHours = nowDate.getHours(),
			nowMinutes = nowDate.getMinutes(),
			nowSeconds = nowDate.getSeconds(),
			nowMilleseconds = (nowHours * 60 * 60 * 1000) + (nowMinutes * 60 * 1000) + (nowSeconds * 1000) + nowDate.getMilliseconds(),
			nowWeekDay = nowDate.getDay(),
			envRefreshWeekDay = env.dialing_refresh.weekday,
			envCheckMilliseconds = (env.check.hours * 60 * 60 * 1000) + (env.check.minutes * 60 * 1000) + (env.check.seconds * 1000) + env.check.milliseconds,
			envRefreshMilliseconds = (env.dialing_refresh.hours * 60 * 60 * 1000) + (env.dialing_refresh.minutes * 60 * 1000) + (env.dialing_refresh.seconds * 1000) + env.dialing_refresh.milliseconds,
			timeoutRefreshMilliseconds = ((envRefreshWeekDay - nowWeekDay) * 24 * 60 * 60 * 1000) + (nowMilleseconds <= envRefreshMilliseconds ? envRefreshMilliseconds - nowMilleseconds : 86400000 - nowMilleseconds + envRefreshMilliseconds + (nowWeekDay == envRefreshWeekDay ? 518400000 : 0)),
			timeoutCheckMilliseconds = nowMilleseconds < envCheckMilliseconds ? envCheckMilliseconds - nowMilleseconds : 86400000 - nowMilleseconds + envCheckMilliseconds;

reducer.initEvents({
	io,
	express,
	nodemailer,
	mysql,
	telegram,
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


reducer.dispatch({
	type: "checkTelegramUpdates",
	data: {

	}
}).then(then).catch(err);

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
}, timeoutCheckMilliseconds);

setTimeout(() => {
	reducer.dispatch({
		type: "query",
		data: {
			query: "resetNotDialAllCompanies",
			values: [
				1
			]
		}
	}).then(responce => {
		setInterval(() => {
			reducer.dispatch({
				type: "query",
				data: {
					query: "resetNotDialAllCompanies",
					values: [
						1
					]
				}
			}).then(then).catch(err);
		}, 518400000);
		then(responce);
	}).catch(err);
}, timeoutRefreshMilliseconds);




		


