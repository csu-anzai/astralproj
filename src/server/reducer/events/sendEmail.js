module.exports = modules => (resolve, reject, data) => {
	modules.nodemailer.sendMail({
		from: '<astralinside@gmail.com>',
		to: data.emails.join(", "),
		subject: data.subject,
		text: data.text
	}, (error, info) => {
		error ? reject(error) : resolve(info);
	});
}