const request = require('request'),
			crypto = require('crypto');
module.exports = (env, reducer) => {
	class VTB {
		constructor(env, reducer){
			this.access_token = {};
			this.refresh_token = {};
			this.auth_token = "";
			this.auth_token_date = "";
			this.key1 = env.vtb.key1;
			this.key2 = env.vtb.key2;
			this.global_refresh_tick = 0;
			this.error_tick = 0;
			this.refresh_timeout_id = "";
			this.refresh_url = env.vtb.refreshUrl;
			this.auth_url = env.vtb.authUrl;
			this.reducer = reducer;
		}
		createToken(){
			this.auth_token_date = new Date();
			let hash = crypto.createHash("sha256").update(`${this.key2}${crypto.createHash("sha256").update(`${this.key1}${this.auth_token_date}`, "uft8").digest("hex")}`, "utf8").digest("hex");
			this.auth_token = `#${this.key1}#${hash}`;
			return this.auth_token;
		}
		getStartToken(createNewAuthToken = true, startRefreshTimeout = true){
			(createNewAuthToken || !this.auth_token) && this.createToken();
			let options = {
				method: "post",
				headers: {
					'Token': this.auth_token,
					'Date': this.auth_token_date
				},
				url: this.auth_url
			};
			this.stopRefreshTimeout();
			this.reducer.modules.log.writeLog("vtb", {
				type: "request",
				options
			});
			request(options, this.responceHandle.bind(this, startRefreshTimeout));
		}
		stopRefreshTimeout(){
			clearTimeout(this.refresh_timeout_id);
			this.refresh_timeout_id = "";
		}
		responceHandle(startRefreshTimeout, err, res, body){
			try {
				typeof body == "string" && (body = JSON.parse(body));
			} catch (err) {
				this.reducer.modules.err(err || body);
				return false;
			}
			if(err || body.status != "1" || !body.access_token || !body.refresh_token){
				this.reducer.modules.err(err || body);
				this.error_tick += 1;
				if(this.error_tick < 5){
					this.getStartToken();
				} else {
					this.reducer.modules.err(`vtb модуль getStartToken тик ошибки: ${this.error_tick}, глобальный тик обновления: ${this.global_refresh_tick}`);
				}
			} else {
				this.reducer.modules.log.writeLog("vtb", {
					type: "responce",
					body
				});
				this.error_tick = 0;
				this.global_refresh_tick += 1;
				this.access_token = body.access_token;
				this.refresh_token = body.refresh_token;
				startRefreshTimeout && this.startRefreshTimeout();
			}
		}
		startRefreshTimeout(){
			let access_token_date = new Date(this.access_token.expiresAt * 1000),
					refresh_token_date = new Date(this.refresh_token.expiresAt * 1000),
					nowDate = new Date(),
					timeoutDate = access_token_date < refresh_token_date ? access_token_date : refresh_token_date,
					timeoutMS = timeoutDate - nowDate;
			timeoutMS <= 0 && (timeoutMS = 0);
			this.refresh_timeout_id && this.stopRefreshTimeout();
			(!this.access_token || !this.refresh_token) && this.getStartToken(true, false);
			this.refresh_timeout_id = setTimeout(() => {
				let options = {
					method: "post",
					headers: {
						'Token': this.access_token.token,
						'Rtoken': this.refresh_token.token
					},
					url: this.refresh_url
				};
				this.reducer.modules.log.writeLog("vtb", {
					type: "request",
					options
				});
				request(options, this.responceHandle.bind(this, true));
			}, timeoutMS);
		}
		getToken(){
			return this.access_token && this.access_token.token || false;
		}
	}
	return new VTB(env, reducer);
}