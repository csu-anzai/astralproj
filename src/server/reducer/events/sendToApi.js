const request = require('request');
module.exports = modules => (resolve, reject, data) => {
	for(let i = 0; i < data.companies.length; i++){
		let company = data.companies[i];
		let body = Object.assign({
			source: "Федеральные партнеры",
			subsource: "API",
			firstName: company.companyPersonName,
			middleName: company.companyPersonPatronymic,
			lastName: company.companyPersonSurname,
			phoneNumber: company.companyPhone,
			companyName: company.companyOrganizationName, 
			innOrOgrn: company.companyInn || company.companyOgrn
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
				modules.reducer.dispatch({
					type: "query",
					data: {
						query: "setApiResponce",
						values: [
							company.companyID,
							body.success ? 1 : 0
						]
					}
				}).then(resolve).catch(reject);
			}
		});
	}
}