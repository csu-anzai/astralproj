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
			let objectString = JSON.stringify({});
			fs.mkdirSync(`./src/server/logs/data/${dateFormated}/`);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/ws.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/errors.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/telegram.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/imap.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/files.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/zadarma.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/system.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/db.json`, objectString);
			fs.writeFileSync(`./src/server/logs/data/${dateFormated}/tinkoff.json`, objectString);
		}
	}
	writeLog(type, object){
		const exists = fs.existsSync(`./src/server/logs/data/${this.dateFormated}/${type}.json`),
					objectString = JSON.stringify(object),
					date = new Date();
		if(!exists && type != "errors"){
			this.writeLog("errors", {
				message: `Лог ${type}.json не найден для внесения записи: ${objectString}`
			});
		} else if(!exists) {
			console.log(`Нет лога ошибок на дату ${date}. Объект ошибки: ${objectString}`);
		} else {
			let log = require(`./data/${this.dateFormated}/${type}.json`),
					date = new Date(),
					timeFormated = `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`;
			log[timeFormated] = object;
			fs.writeFileSync(`./src/server/logs/data/${this.dateFormated}/${type}.json`, JSON.stringify(log));
		}
	}
}
module.exports = (env, reducer) => {
	const log = new Log();
	return log;
}