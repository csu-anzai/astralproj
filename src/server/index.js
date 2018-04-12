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
