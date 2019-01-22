const request = require("request");
module.exports = (env, reducer) => {
	class Dadata {
		constructor(env, reducer){
			this.url = env.dadata.url;
			this.token = env.dadata.token;
			this.dayRequestMaxCount = env.dadata.requestCount;
			this.dayRequestCount = 0;
			this.reducer = reducer;
			this.timeoutID = null;
			this.restartTimeout();
		}
		getCompanyInformation(inn){
			let options = {
				method: "post",
				headers: {
					'Content-Type': "application/json",
					'Accept': "application/json",
					'Authorization': `Token ${this.token}`
				},
				body: {
					query: inn,
					branch_type: "MAIN"
				},
				json: true,
				url: this.url
			};
			if (this.dayRequestCount < this.dayRequestMaxCount) {
				return new Promise((resolve, reject) => {
					this.dayRequestCount += 1;
					this.reducer.modules.log.writeLog("dadata", {
						type: "request",
						info: `Запрос ${this.dayRequestCount}/${this.dayRequestMaxCount}`,
						options
					});
					request(options, (err, res, body) => {						
						this.reducer.modules.log.writeLog("dadata", {
							type: "responce",
							body
						});
						if (err) {
							this.reducer.modules.err(err || body);
							reject(err || body);
						} else {
							typeof body == "string" && (body = JSON.parse(body));
							resolve(body);
						}
					});
				});
			} else {
				this.reducer.modules.log.writeLog("dadata", {
					type: "info",
					message: `Достигнут лимит запросов на день: ${this.dayRequestCount}/${this.dayRequestMaxCount}`
				});
			}
		}
		restartTimeout(){
			let date = new Date(),
					nowHours = date.getHours(),
					nowMinutes = date.getMinutes(),
					nowSeconds = date.getSeconds(),
					nowMilliseconds = date.getMilliseconds(),
					nowTimeInMilliseconds = (nowHours * 3600000) + (nowMinutes * 60000) + (nowSeconds * 1000) + nowMilliseconds,
					timeoutTime = 86400000 - nowTimeInMilliseconds;
			this.dayRequestCount = 0;
			this.timeoutID = setTimeout(this.restartTimeout, timeoutTime);
		}
	}
	return new Dadata(env, reducer);
}