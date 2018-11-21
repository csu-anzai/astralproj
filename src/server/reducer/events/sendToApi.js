const request = require('request'),
			xml = require("xml-parse");
module.exports = modules => (resolve, reject, data) => {
	switch(+data.bankID){
		case 1: {
			let options = {
				method: 'post',
				body: Object.assign({
					firstName: data.companyPersonName,
					middleName: data.companyPersonPatronymic,
					lastName: data.companyPersonSurname,
					phoneNumber: data.companyPhone,
					product: "РКО",
					companyName: data.companyOrganizationName,
					source: "Федеральные партнеры",
					subsource: "API",
					innOrOgrn: data.companyInn || data.companyOgrn,
					comment: data.companyComment,
					isHot: true,
				}, modules.env.tinkoff.body),
				url: modules.env.tinkoff.applicationUrl,
				json: true
			};
			modules.log.writeLog("tinkoff", {
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
								body.result && body.result.applicationId || "false",
								body.requestId,
								body.success ? 1 : 0
							]
						}
					}).then(resolve).catch(reject);
					modules.log.writeLog("tinkoff", {
						type: "responce",
						body
					});
				}
			});
		}
		break;
		case 2: {
			let options = {
				method: "post",
				body: Object.assign({
					firstName: data.companyPersonName,
					middleName: data.companyPersonPatronymic,
					lastName: data.companyPersonSurname,
					phoneNumber: data.companyPhone,
					product: "РКО",
					companyName: data.companyOrganizationName,
					[data.companyInn ? "inn" : "ogrn"]: data.companyInn || data.companyOgrn
				}, modules.env.modul.body),
				url: modules.env.modul.applicationUrl,
				json: true
			};
			modules.log.writeLog("modul", {
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
								body.applicationId || "false",
								body.requestId,
								body.success ? 1 : 0
							]
						}
					}).then(resolve).catch(reject);
					modules.log.writeLog("modul", {
						type: "responce",
						body
					});
					modules.reducer.dispatch({
						type: "sendEmail",
						data: {
							emails: [
								modules.env.modul.email
							],
							subject: `Лид от Астрал.инсайда ${data.companyOrganizationName} / ${data.companyInn}`,
							text: `Ф.И.О.: ${[data.companyPersonName, data.companyPersonSurname, data.companyPersonPatronymic].join(" ")}\nТелефон: ${data.companyPhone}\nНазвание: ${data.companyOrganizationName}\nИНН: ${data.companyInn}\nИдентификатор запроса: ${body.requestId}\nИдентификатор заявки: ${body.applicationId}\nКоментарий: ${data.companyComment}`
						}
					}).then(modules.then).catch(modules.err);
				}
			});
		}
		break;
		case 3: {
			let applicationId = "1".repeat(Math.floor(Math.random()*3)+10).split("").map(() => Math.floor(Math.random()*10)).join("");
			let options = {
				method: "post",
				body: `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:ru.psbank.webservices"><soapenv:Header /><soapenv:Body><urn:ProcessFormDataWithResponse><urn:formData><FormGuid>F3AA3CE8-3A9C-4EB9-8A57-902851E24AED</FormGuid><Data><Key>A8A548B6-0426-421E-887F-145013011E5A</Key><Value>${data.companyComment || ''}</Value></Data><Data><Key>F9C02B1A-6C91-4100-A0E4-769194159DF0</Key><Value>${data.templateTypeID == 11 ? 4 : 1}</Value></Data><Data><Key>54952415-C2E6-4E60-8173-59C8883443DA</Key><Value>${data.companyOrganizationName || ''}</Value></Data><Data><Key>A97B7E7A-55BE-47A5-85E8-F29604AFDD66</Key><Value>${data.companyInn || ''}</Value></Data><Data><Key>5C911979-769B-41B5-AE2F-C82743FAE71A</Key><Value>${data.companyPersonName || ''}</Value></Data><Data><Key>7277E008-8FC0-40AA-8B2E-10FB8F606E1F</Key><Value>${data.companyPhone ? data.companyPhone.replace("+7", "") : ''}</Value></Data><Data><Key>BAE4DCDE-537D-43A6-8F64-E96DF3E753B5</Key><Value>${data.companyEmail || ''}</Value></Data><Data><Key>116DD0EC-6C11-494E-8710-74F9342F4230</Key><Value>${data.bankFilialRegionApiCode || ''}</Value></Data><Data><Key>35F9E22C-7C08-4B76-B4F3-1857E4546F5A</Key><Value>${data.bankFilialApiCode || ''}</Value></Data><Data><Key>E1FBA727-ABB6-4A4D-9136-BB4E258508E9</Key><Value>1</Value></Data><Data><Key>57E8C256-F118-40F4-B7DC-611F2BBFA4C7</Key><Value>${applicationId || ""}</Value></Data><Data><Key>95FDCE7D-2ACB-4446-9705-7B9EDF41B6E9</Key><Value></Value></Data><Data><Key>F63886D3-ABB9-469D-AD35-35DDFEF989CB</Key><Value></Value></Data><Data><Key>7395BCA7-C8B4-405E-92DC-D70ACC0E19BC</Key><Value></Value></Data><Data><Key>D94C6B80-B6BC-4667-8A22-B2DE9CDE18A4</Key><Value></Value></Data><Data><Key>53C7EFE6-607F-4E4A-A028-90ADADD13343</Key><Value>PartnersEB</Value></Data><Data><Key>F3AC4BBE-AEE4-4B9D-8BB7-E0923FEC3905</Key><Value></Value></Data><Data><Key>0B76C7ED-D068-44F2-AFB1-591BD7F1489A</Key><Value>КалугаАстрал</Value></Data><Data><Key>9DB6E8B8-D503-4751-9C6A-6BABCA0FFDCE</Key><Value></Value></Data></urn:formData><urn:leadGenId>57E8C256-F118-40F4-B7DC-611F2BBFA4C7</urn:leadGenId></urn:ProcessFormDataWithResponse></soapenv:Body></soapenv:Envelope>`,
				url: modules.env.promsvyaz.applicationUrl,
				headers: Object.assign({
					"Content-Type": "text/xml; charset=utf-8"
				}, modules.env.promsvyaz.headers)
			};
			modules.log.writeLog("promsvyaz", {
				type: "request",
				options
			});
			request(options, (err, res, body) => {
				if(err){
					reject(err);
				} else {
					let xmlResult = xml.parse(body),
							answer = xmlResult && 
											 xmlResult[2] && 
											 xmlResult[2].childNodes && 
											 xmlResult[2].childNodes[0] && 
											 xmlResult[2].childNodes[0].childNodes && 
											 xmlResult[2].childNodes[0].childNodes[2] && 
											 xmlResult[2].childNodes[0].childNodes[2].childNodes && 
											 xmlResult[2].childNodes[0].childNodes[2].childNodes[0] && 
											 xmlResult[2].childNodes[0].childNodes[2].childNodes[0].text || false;
					modules.reducer.dispatch({
						type: "query",
						data: {
							query: "setApiResponce",
							values: [
								data.companyID,
								applicationId || "false",
								null,
								(answer != false && answer == "ACCEPTED") ? 1 : 0
							]
						}
					}).then(resolve).catch(reject);
					modules.log.writeLog("promsvyaz", {
						type: "responce",
						body
					});
				}
			});
		}
		break;
		case 4: {
			let options = {
				method: "post",
				headers: {
					'Token': modules.vtb.getToken()
				},
				url: modules.env.vtb.newAnketaUrl
			};
			modules.log.writeLog("vtb", {
				type: "request",
				options
			});
			request(options, (err, res, body) => {
				if(err){
					reject(err);
				} else {
					typeof body == "string" && (body = JSON.parse(body));
					modules.log.writeLog("vtb", {
						type: "responce",
						body
					});
					let applicationId = body.id_anketa,
							options = {
								method: "post",
								headers: {
									'Token': modules.vtb.getToken(),
									'content-type': 'application/x-www-form-urlencoded'
								},
								body: `anketadata=${JSON.stringify({
									org_name: data.companyOrganizationName || "",
									inn: data.companyInn || "",
									region: data.regionCode || "",
									branch: data.bankFilialApiCode || "",
									contact_phone: data.companyPhone || "",
									add_info: data.companyComment || "",
									agreement: 1,
									city: data.cityName || "",
									fio: [data.companyPersonName, data.companyPersonSurname, data.companyPersonPatronymic].join(" ")
								})}`,
								url: modules.env.vtb.editAnketaUrl.replace("${id}", applicationId)
							};
					modules.log.writeLog("vtb", {
						type: "request",
						options
					});
					request(options, (err, res, body) => {
						if(err){
							reject(err);
						} else {
							typeof body == "string" && (body = JSON.parse(body));
							modules.log.writeLog("vtb", {
								type: "responce",
								body
							});
							if(+body.status_code == 1){
								let options = {
									method: "post",
									headers: {
										'Token': modules.vtb.getToken()
									},
									body: {
										comment: `Ф.И.О.: ${[data.companyPersonName, data.companyPersonSurname, data.companyPersonPatronymic].join(" ")}\n${data.companyComment}`
									},
									json: true,
									url: modules.env.vtb.applyAnketaUrl.replace("${id}", applicationId)
								};
								modules.log.writeLog("vtb", {
									type: "request",
									options
								});
								request(options, (err, res, body) => {
									if(err){
										reject(err);
									} else {
										typeof body == "string" && (body = JSON.parse(body));
										modules.log.writeLog("vtb", {
											type: "responce",
											body
										});
										modules.reducer.dispatch({
											type: "query",
											data: {
												query: "setApiResponce",
												values: [
													data.companyID,
													applicationId || "false",
													null,
													+body.status_code == 1 ? 1 : 0
												]
											}
										}).then(resolve).catch(reject);
									}
								});
							} else {
								modules.reducer.dispatch({
									type: "query",
									data: {
										query: "setApiResponce",
										values: [
											data.companyID,
											applicationId || "false",
											null,
											0
										]
									}
								}).then(resolve).catch(reject);
							}
						}
					});
				}
			});
		}
		break;
	}
}