const request = require('request');
module.exports = modules => (resolve, reject, data) => {
	if(data.bankID != 3){
		let template = {
			firstName: data.companyPersonName,
			middleName: data.companyPersonPatronymic,
			lastName: data.companyPersonSurname,
			phoneNumber: data.companyPhone,
			product: "РКО",
			companyName: data.companyOrganizationName
		};
		let bankName = data.bankID == 1 ? "tinkoff" : data.bankID == 2 && "modul";
		let body = Object.assign(data.bankID == 1 ? {
			source: "Федеральные партнеры",
			subsource: "API",
			innOrOgrn: data.companyInn || data.companyOgrn,
			comment: data.companyComment
		} : data.bankID == 2 && {
			[data.companyInn ? "inn" : "ogrn"]: data.companyInn || data.companyOgrn
		}, modules.env[bankName].body, template);
		
		let options = {
			method: 'post',
			body: body,
			json: true,
			url: modules.env[bankName].applicationUrl
		};
		modules.log.writeLog(bankName, {
			type: "request",
			options
		});
		request(options, (err, res, body) => {
			if(err){
				reject(err);
			} else {
				modules.reducer.dispatch({
					type: "query",
					data: {
						query: "setApiResponce",
						values: [
							data.companyID,
							(body.hasOwnProperty("result") && body.result.hasOwnProperty("applicationId")) ?
								body.result.applicationId :
								body.applicationId || "false",
							body.requestId,
							body.success ? 1 : 0
						]
					}
				}).then(resolve).catch(reject);
			}
			modules.log.writeLog(bankName, {
				type: "responce",
				body
			});
		});
	} else {
		modules.reducer.dispatch({
			type: "sendEmail",
			data: {
				emails: [
					modules.env.promsvyaz.email
				],
				subject: `Лид Астрал.Инсайд （${[data.companyInn,data.companyPhone,data.companyOrganizationName].join("/")})`,
				text: `Название компании: ${data.companyOrganizationName || "–"}\nФ.И.О. контактного лица: ${[data.companyPersonName, data.companyPersonSurname, data.companyPersonPatronymic].join(" ") || "–"}\nТелефон: ${data.companyPhone || "–"}\nИНН: ${data.companyInn || "–"}\nОГРН: ${data.companyOgrn || "–"}\nКомментарий: ${data.companyComment || "–"}`
			}
		}).then(responce => {
			modules.reducer.dispatch({
				type: "query",
				data: {
					query: "setApiResponce",
					values: [
						data.companyID,
						null,
						null,
						1
					]
				}
			}).then(modules.then).catch(modules.err);
			modules.then(responce);
		}).catch(responce => {
			modules.reducer.dispatch({
				type: "query",
				data: {
					query: "setApiResponce",
					values: [
						data.companyID,
						null,
						null,
						0
					]
				}
			}).then(modules.then).catch(modules.err);
			modules.err(responce);
		});
	}
}