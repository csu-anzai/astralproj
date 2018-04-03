const env = require('../env.json'),
			reducer = new (require('./reducer/')),
			express = require('./express')(env, reducer),
			io = require('./io')(env, express, reducer),
			nodemailer = require('./nodemailer')(env),
			mysql = require('./mysql')(env),
			imap = require('./imap')(env, reducer);
reducer.initEvents({
	io,
	nodemailer,
	mysql,
	reducer
});
reducer.dispatch({
	type: "query",
	data: {
		query: "disconnectAll",
		values: []
	}
});
