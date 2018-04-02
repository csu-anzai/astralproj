const request = require('request');
module.exports = modules => (resolve, reject, data) => {
	for(let i = 0; i < data.companies.length; i++){
		let company = data.companies[i];
		let body = {
			securityKey: "e033e878c973539ce57904035c4124dd",
			partnerId: "5-89EH1KOQ",
			agentId: "5-89IFZIE6",
			source: "Федеральные партнеры",
			subsource: "API",
			firstName: company.companyPersonName,
			middleName: company.companyPersonPatronymic,
			lastName: company.companyPersonSurname,
			phoneNumber: company.companyPhone,
			companyName: company.companyOrganizationName, 
			innOrOgrn: company.companyInn || company.companyOgrn
		};
		let options = {
			method: 'post',
			body: body,
			json: true,
			url: "https://origination.tinkoff.ru/api/v1/public/partner/createApplication"
		};
		request(options, (err, res, body) => {
			if(err){
				console.log(err);
			} else {
				console.log(body);
			}
		});
	}
}