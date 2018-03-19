const nodemailer = require('nodemailer');
module.exports = env => {
	let transporter = nodemailer.createTransport(env.nodemailer);
	return transporter;
}