const request = require('request');
module.exports = modules => (resolve, reject, data) => {
		let body = Object.assign({
			source: "Федеральные партнеры",
			subsource: "API",
			firstName: data.companyPersonName,
			middleName: data.companyPersonPatronymic,
			lastName: data.companyPersonSurname,
			phoneNumber: data.companyPhone,
			companyName: data.companyOrganizationName, 
			innOrOgrn: data.companyInn || data.companyOgrn,
			comment: data.companyComment
		}, modules.env.tinkoff);
		let options = {
			method: 'post',
			body: body,
			json: true,
			url: modules.env.tinkoff.url
		};
		request(options, (err, res, body) => {
			if(err){
				reject(err);
			} else {
				if (body.success == 0) {
					console.log(body);
				}
				modules.reducer.dispatch({
					type: "query",
					data: {
						query: "setApiResponce",
						values: [
							data.companyID,
							(body.hasOwnProperty("result") && body.result.hasOwnProperty("applicationId")) ?
								body.result.applicationId :
								"false",
							body.requestId,
							body.success ? 1 : 0
						]
					}
				}).then(resolve).catch(reject);
			}
		});
}