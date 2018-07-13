const tr = require("tor-request"),
			err = require("../err");
let then = require("../then");
class TelegramApi {
	constructor(env, reducer){
		this.telegramApiUrl = `https://api.telegram.org/bot${env.telegram.token}`;
		this.reducer = reducer;
		this.requestOptions = {
			method: "POST",
			json: true
		}
	}
	getUpdates(offset = 0, limit = 10, timeout = 0, allowed_updates = ["message"]){
		const options = Object.assign({
			body: {
				offset: offset,
				limit: limit,
				timeout: timeout,
				allowed_updates: allowed_updates
			},
			url: `${this.telegramApiUrl}/getUpdates`
		}, this.requestOptions);
		return new Promise((resolve, reject) => {
			tr.newTorSession(error => {
				error ? reject(error) : 
				tr.request(options, (err, res, body) => {
					err ? reject(err) : resolve(body);
				});
			});
		});
	}
	sendMessage(chat_id, text, parse_mode, disable_web_page_preview = false, disable_notification = false, reply_to_message_id, reply_markup){
		if (chat_id && text) {
			const options = Object.assign({
				body: {
					chat_id,
					text,
					parse_mode,
					disable_web_page_preview,
					disable_notification,
					reply_to_message_id,
					reply_markup
				},
				url: `${this.telegramApiUrl}/sendMessage`
			}, this.requestOptions);
			!parse_mode && delete(options.body.parse_mode);
			!reply_to_message_id && delete(options.body.reply_to_message_id);
			!reply_markup && delete(options.body.reply_markup);
			return new Promise((resolve, reject) => {
				tr.newTorSession(error => {
					error ? reject(error) :
					tr.request(options, (err, res, body) => {
						err ? reject(err) : resolve(body);
					});
				});
			});
		}
	}
}
module.exports = (env, reducer) => {
	tr.TorControlPort.password = env.tor.password;
	const api = new TelegramApi(env, reducer);	
	return api;
}