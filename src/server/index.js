const env = require('../env.json'),
			reducer = new (require('./reducer/')),
			express = require('./express')(env, reducer),
			io = require('./io')(env, express, reducer),
			nodemailer = require('./nodemailer')(env),
			mysql = require('./mysql')(env),
			imap = require('./imap')(env, reducer),
			telegram = require('./telegram')(env, reducer),
			err = require('./err').bind(this, reducer),
		 	then = require('./then').bind(this, reducer),
		 	log = require('./logs')(),
		 	vtb = require('./vtb')(env, reducer),
		 	dadata = require('./dadata')(env, reducer),
		 	nowDate = new Date(),
			nowHours = nowDate.getHours(),
			nowMinutes = nowDate.getMinutes(),
			nowSeconds = nowDate.getSeconds(),
			nowMilleseconds = (nowHours * 60 * 60 * 1000) + (nowMinutes * 60 * 1000) + (nowSeconds * 1000) + nowDate.getMilliseconds(),
			nowWeekDay = nowDate.getDay(),
			envRefreshWeekDay = env.dialing_refresh.weekday,
			envCheckMilliseconds = (env.check.hours * 60 * 60 * 1000) + (env.check.minutes * 60 * 1000) + (env.check.seconds * 1000) + env.check.milliseconds,
			envRefreshMilliseconds = (env.dialing_refresh.hours * 60 * 60 * 1000) + (env.dialing_refresh.minutes * 60 * 1000) + (env.dialing_refresh.seconds * 1000) + env.dialing_refresh.milliseconds,
			envStatisticMilliseconds = (env.statistic.hours * 60 * 60 * 1000) + (env.statistic.minutes * 60 * 1000) + (env.statistic.seconds * 1000) + env.statistic.milliseconds,
			envRefreshFilialsMilliseconds = (env.refresh_filials.hours * 60 * 60 * 1000) + (env.refresh_filials.minutes * 60 * 1000) + (env.refresh_filials.seconds * 1000) + env.refresh_filials.milliseconds,
			envResetCallsMilliseconds = (env.reset_calls.hours * 60 * 60 * 1000) + (env.reset_calls.minutes * 60 * 1000) + (env.reset_calls.seconds * 1000) + env.reset_calls.milliseconds,
			timeoutRefreshMilliseconds = ((envRefreshWeekDay - nowWeekDay) * 24 * 60 * 60 * 1000) + (nowMilleseconds <= envRefreshMilliseconds ? envRefreshMilliseconds - nowMilleseconds : 86400000 - nowMilleseconds + envRefreshMilliseconds + (nowWeekDay == envRefreshWeekDay ? 518400000 : 0)),
			timeoutStatisticMilliseconds = nowMilleseconds < envStatisticMilliseconds ? envStatisticMilliseconds - nowMilleseconds : 86400000 - nowMilleseconds + envStatisticMilliseconds,
			timeoutRefreshFilialsMilliseconds = nowMilleseconds < envRefreshFilialsMilliseconds ? envRefreshFilialsMilliseconds - nowMilleseconds : 86400000 - nowMilleseconds + envRefreshFilialsMilliseconds,
			timeoutResetCallsMilliseconds = nowMilleseconds < envResetCallsMilliseconds ? envResetCallsMilliseconds - nowMilleseconds : 86400000 - nowMilleseconds + envResetCallsMilliseconds,
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
	err,
	log,
	vtb,
	dadata
});

reducer.dispatch({
	type: "getCompaniesInformation",
	data: {
		companies: [
			{
				company_id: 1,
				company_inn: 410119932600
			},
			{
				company_id: 2,
				company_inn: 410111154028
			},
			{
				company_id: 3,
				company_inn: 410909139945
			}
		]
	}
});

setTimeout(() => {
	setTimeout(() => {
		reducer.dispatch({
			type: "refreshVtbFilials",
			data: [

			]
		}).then(then).catch(err);
	}, 86400000)
}, timeoutRefreshFilialsMilliseconds);

vtb.getStartToken();

reducer.dispatch({
	type: "query",
	data: {
		query: "serverStart",
		values: []
	}
}).then(then).catch(err);

reducer.dispatch({
	type: "checkTelegramUpdates",
	data: {

	}
}).then(then).catch(err);

/*setTimeout(() => {
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
}, timeoutCheckMilliseconds);*/

setTimeout(() => {
	reducer.dispatch({
		type: "query",
		data: {
			query: "resetNotDialAllCompanies",
			values: [
				
			]
		}
	}).then(responce => {
		setInterval(() => {
			reducer.dispatch({
				type: "query",
				data: {
					query: "resetNotDialAllCompanies",
					values: [
						
					]
				}
			}).then(then).catch(err);
		}, 518400000);
		then(responce);
	}).catch(err);
}, timeoutRefreshMilliseconds);

setTimeout(() => {
	reducer.dispatch({
		type: "telegramDayStatistic",
		data: [

		]
	}).then(responce => {
		setInterval(() => {
			reducer.dispatch({
				type: "telegramDayStatistic",
				data: [

				]
			}).then(then).catch(err);
		}, 86400000);
		then(responce);
	}).catch(err);
}, timeoutStatisticMilliseconds);

setTimeout(() => {
	reducer.dispatch({
		type: "resetCalls",
		data: [

		]
	}).then(responce => {
		setInterval(() => {
			reducer.dispatch({
				type: "resetCalls",
				data: [

				]
			}).then(then).catch(err);
		}, 86400000);
		then(responce);
	}).catch(err);
}, timeoutResetCallsMilliseconds);



		


