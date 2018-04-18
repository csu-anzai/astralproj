const mailListener = require("mail-listener2"),
			xlsx = require("xlsx"),
			err = require("./../err");
let then = require("./../then");
module.exports = (env, reducer) => {
	then = then.bind(this, reducer);
	const imap = new mailListener(Object.assign(env.imap, {
		attachmentOptions: {
			directory: __dirname + "/../" + env.imap.attachmentOptions.directory
		}
	}));
	imap.start();
	imap.on("server:connected", () => {
		console.log("\nconnect to imap server\n");
	});
	imap.on("server:disconnected", () => {
		const imap = require("./")(env, reducer);
		reducer.initEvents({imap});
		console.log("\ndisconnect from imap server\n");
	});
	imap.on("error", err => {
		console.log("\nerror from imap connection: ", err, "\n");
	});
	imap.on("attachment", attachment => {
		console.log("new file in: ", attachment.path);
		let sheetRows = {};
		try {
			const workbook = xlsx.readFile(attachment.path),
						first = Object.keys(workbook.Sheets)[0],
						sheet = workbook.Sheets[first];
			console.log(Object.keys(workbook));
			/*for(key in sheet){
				if (!/!/.test(key)){
					let param = sheet[key].v,
							numbers = key.match(/\d+/)[0],
							str = key.split(numbers).join("").toLowerCase(),
							row = numbers != 1 ? "r" + numbers : "columns";
						sheetRows[row] &&
							(sheetRows[row][str] = param) ||
							(sheetRows[row] = {[str]: param});
				}
			}
			if (sheetRows) {
				console.log("transform xlsx file to json format well done. File have " + (Object.keys(sheetRows).length - 1) + " rows. Date " + new Date() + "\n");
				reducer.dispatch({
					type: "saveParseResult",
					data: sheetRows
				}).then(then).catch(err);
			} else {
				console.log("transform xlsx file to json format have error. JSON result: " + sheetRows);
			}*/
		} catch(err) {
			console.log(err);
		}
	});
	imap.on("done", attachment => {
		console.log("done\n");
	});
	return imap;
}