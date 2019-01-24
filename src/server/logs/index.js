const fs = require('fs');
class Log {
	constructor(){
		const date = new Date(),
					milliseconds = date.getHours() * 60 * 60 * 1000 + date.getMinutes() * 60 * 1000 + date.getSeconds() * 1000 + date.getMilliseconds(),
					dayMilliseconds = 86400000,
					differenceMilliseconds = dayMilliseconds - milliseconds;
		this.checkLogs();
		setTimeout(() => {
			this.checkLogs();
			setInterval(this.checkLogs, dayMilliseconds);
		}, differenceMilliseconds + 1);
	}
	checkLogs(){
		let date = new Date(),
				dateFormated = `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
		this.date = date;
		this.dateFormated = dateFormated;
		!fs.existsSync(`./src/server/logs/data/`) && fs.mkdirSync(`./src/server/logs/data`);
		if(!fs.existsSync(`./src/server/logs/data/${dateFormated}`)){
			fs.mkdirSync(`./src/server/logs/data/${dateFormated}/`);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/ws.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/errors.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/telegram.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/imap.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/files.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/zadarma.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/system.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/db.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/tinkoff.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/modul.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/promsvyaz.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/email.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/vtb.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/alfa.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/sberbank.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/open.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/tochka.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/raiffaisen.txt`, "");
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/ubrr.txt`, "");
		}
	}
	writeLog(type, object){
		const exists = fs.existsSync(`./src/server/logs/data/${this.dateFormated}/${type}.txt`),
					objectString = JSON.stringify(object),
					date = new Date();
		if(!exists && type != "errors"){
			this.writeLog("errors", {
				message: `Лог ${type}.txt не найден для внесения записи: ${objectString}`
			});
		} else if(!exists) {
			console.log(`Нет лога ошибок на дату ${date}. Объект ошибки: ${objectString}`);
		} else {
			let date = new Date(),
					timeFormated = `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
			fs.appendFileSync(`./src/server/logs/data/${this.dateFormated}/${type}.txt`, `${timeFormated} – ${objectString}\n\n`);
		}
	}
}
module.exports = (env, reducer) => {
	const log = new Log();
	return log;
}