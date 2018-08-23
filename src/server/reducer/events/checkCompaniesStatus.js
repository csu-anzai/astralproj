const request = require('request');
module.exports = modules => (resolve, reject, data) => {
	modules.reducer.dispatch({
		type: "query",
		data: {
			query: "getCompaniesToCheckStatus",
			values: [
				data.user_hash || null
			]
		}
	}).then(responce => {
		responce = JSON.parse(responce[0].a);
		let companies = responce.companies;
		if (companies && companies instanceof Array && companies.length > 0){
			let options = {
				url: modules.env.tinkoff.checkUrl,
				headers: {
					Authorization: `Partner partnerId="${modules.env.tinkoff.body.partnerId}", securityKey="${modules.env.tinkoff.body.securityKey}"`
				},
				method: 'post',
				json: true,
				body: companies.map(company => company.applicationID)
			};
			request(options, (err, res, body) => {
				if(err){
					reject(err);
				} else {
					companies = [];
					const types = {
						APPLICATION_CREATED: 16,
						APPLICATION_DOUBLE: 24,
						DOC_UPLOAD: 25,
						PROCESSING: 26,
						MEETING_WAITING: 27,
						MEETING_SCHEDULED: 28,
						POSTPROCESSING: 29,
						ACCEPTED: 30,
						BANK_REJECTION: 31,
						CLIENT_REFUSAL: 32
					};
					const result = body.result;
					if (result instanceof Array && result.length > 0){
						for (let i = 0; i < result.length; i++){
							let company = result[i];
							companies.push({
								company_application_id: company.id,
								type_id: types[company.status]
							});
						}
						modules.reducer.dispatch({
							type: "query",
							data: {
								query: "setCheckResponce",
								values: [
									JSON.stringify(companies)
								]
							}
						}).then(resolve).catch(reject)
					}
				}
			});
			modules.reducer.dispatch({
				type: "print",
				data: {
					message: `Отправлено на уточнение статуса ${companies.length} компаний`,
					user_id: data.user_id
				}
			}).then(modules.then).catch(modules.err);
		}
	}).catch(reject);
}