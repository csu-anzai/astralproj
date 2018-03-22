const mailListener = require("mail-listener2");
module.exports = (env, reducer) => {
	const imap = new mailListener(Object.assign(env.imap, {
		attachmentOptions: {
			directory: __dirname + "/../" + env.imap.attachmentOptions.directory
		}
	}));
	imap.start();
	imap.on("server:connected", () => {
		console.log("connect to imap server\n");
	});
	imap.on("server:disconnected", () => {
		console.log("disconnect from imap server\n");
	});
	imap.on("error", err => {
		console.log("error from imap connection: ", err, "\n");
	});
	imap.on("attachment", attachment => {
		console.log("new file in: ", attachment.path, "\n");
	});
	imap.on("done", attachment => {
		console.log("done\n");
	});
	return imap;
}