const env = require('../env.json'),
			reducer = new (require('./reducer/')),
			express = require('./express')(env, reducer),
			io = require('./io')(env, express, reducer),
			nodemailer = require('./nodemailer')(env),
			mysql = require('./mysql')(env);
reducer.initEvents({
	io,
	nodemailer,
	mysql
});
