const mailListener = require("mail-listener2"),
			xlsx = require("xlsx");
let then = require("./../then"),
		err = require("./../err");
module.exports = (env, reducer) => {
	then = then.bind(this, reducer);
	err = err.bind(this, reducer);
	let envClone = JSON.parse(JSON.stringify(env));
	const imap = new mailListener(Object.assign(envClone.imap, {
		attachmentOptions: {
			directory: __dirname + "/../" + envClone.imap.attachmentOptions.directory
		}
	}));
	imap.start();
	imap.on("server:connected", () => {
		reducer.modules.log.writeLog("imap","соединение с сервером imap установлено");
	});
	imap.on("server:disconnected", () => {
		const imap = require("./")(env, reducer);
		reducer.initEvents({imap});
		reducer.modules.log.writeLog("imap","соединение с сервером imap разорвано");
	});
	imap.on("error", err => {
		reducer.modules.log.writeLog("errors","ошибка в imap соединении: ", err);
	});
	imap.on("mail", (mail, seqno, attributes) => {
		let titleNumbersArray = mail.subject && mail.subject.match(/\d+/g),
				fileNameArray = [],
				fileExt = "";
		if(mail.attachments && mail.attachments[0]){
			fileNameArray = mail.attachments[0].fileName.split(".");
			fileExt = fileNameArray[fileNameArray.length - 1];
		}
		if(fileExt == "mp3" && titleNumbersArray.length == 2){
			let fileName = mail.attachments[0].fileName,
					sipID = titleNumbersArray.find(number => number.length == 3),
					phoneNum = titleNumbersArray.find(number => number != sipID),
					filePath = `${env.ws.location}:${env.ws.port}/${fileName}`;
			if(sipID && fileName){
				reducer.dispatch({
					type: "query",
					data: {
						query: "setRecordFile",
						values: [
							sipID,
							phoneNum || null,
							fileName,
							filePath,
							(!phoneNum || titleNumbersArray.findIndex(i => i == sipID) == 1) ? 1 : 0
						]
					}
				}).then(then).catch(err);
			}
		}
	});
	imap.on("attachment", attachment => {
		reducer.modules.log.writeLog("files", {type: "attachment", path: attachment.path});
		let fileName = attachment.generatedFileName,
				fileNameArray = fileName.split("."),
				fileExt = fileNameArray.length > 0 ? fileNameArray[fileNameArray.length - 1] : null;
		if(fileExt != null){
			if(fileExt == "xlsx" || fileExt == "xls"){
				try {
					let sheetRows = {};
					const workbook = xlsx.readFile(attachment.path),
								first = Object.keys(workbook.Sheets)[0],
								sheet = workbook.Sheets[first];
					for(key in sheet){
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
						reducer.modules.log.writeLog("system", "Чтение exel файла завершено. В файле " + (Object.keys(sheetRows).length - 1) + " строк. Дата: " + new Date());
						reducer.dispatch({
							type: "saveParseResult",
							data: sheetRows
						}).then(then).catch(err);
					} else {
						reducer.modules.log.writeLog("errors", "Ошибка чтения exel файла. Результат чтения: " + sheetRows);
						reducer.dispatch({
							type: "print",
							data: {
								message: "Ошибка чтения exel файла. Результат чтения: " + sheetRows,
								telegram: 1
							}
						}).then(then).catch(err);
					}
				} catch(err) {
					reducer.modules.log.writeLog("errors", `ошибка в чтении exel файла: ${err}`);
					reducer.dispatch({
						type: "print",
						data: {
							message: `ошибка в чтении exel файла: ${err}`,
							telegram: 1
						}
					}).then(then).catch(err);
				}
			}
		}
	});
	imap.on("done", attachment => {
		reducer.modules.log.writeLog("imap","done");
	});
	return imap;
}