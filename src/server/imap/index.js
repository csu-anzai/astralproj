const mailListener = require("mail-listener");
module.exports = env => {
	const imap = new mailListener(env.imap);
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
		console.log("new file in: ", attachment.path, "/n");
	});
	imap.on("done", attachment => {
		console.log("done\n");
	});
	return imap;
}