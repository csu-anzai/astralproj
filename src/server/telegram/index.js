const TelegramBot = require('node-telegram-bot-api');
const Agent = require('socks5-https-client/lib/Agent');

const err = require("../err");
const then = require("../then");
const logs = require("../logs")();

class TelegramApi {
	constructor(env, reducer){
		this.bot = new TelegramBot(env.telegram.token, {
		  polling: true,
		  // Подключение и настройка прокси socks5-https-client
		  request: {
		    agentClass: Agent,
		    agentOptions: {
		      socksHost: env.proxy.host,
		      socksPort: env.proxy.port
		    }
		  }
		})
		this.bot.on('error', error => {
			logs.writeLog("telegram", error);
		});
	}

	getUpdates(callback){
		// Подписывание на получение всех объектов сообщений
		this.bot.on('message', msg => callback(msg));
	}

	sendMessage(chat_id, text){
		// Отправка сообщения
		if (chat_id && text) {
			logs.writeLog("telegram", {chat_id, text});
			return this.bot.sendMessage(chat_id, text).catch((error) => {
				logs.writeLog("telegram", error);
			});
		}
	}
}

module.exports = (env, reducer) => {
	const api = new TelegramApi(env, reducer);	
	return api;
}