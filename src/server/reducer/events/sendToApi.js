const request = require('request'),
			xml = require("xml-parse"),
			crypto = require("crypto"),
			companyPresenter = require('../../../../src/presenters/company.js'),
			jsonConvertor = text => {
				let json = {};
				try {
					 json = JSON.parse(text);
					 return json;
				} catch (err) {
					return text;
				}
			},
			transformCyrillicToUnicode = string => string.split("").map(item => {
				if(/[аА-яЯ]/.test(item)) {
					let numbers = item.charCodeAt(0).toString(16),
							numbersLength = numbers.length,
							unicode = `\\u${"0".repeat(4 - numbersLength)}${numbers}`;
					return unicode;
				} else {
					return item;
				}
			}).join("");
module.exports = modules => (resolve, reject, data) => {
	console.log('data: ', data);
	data = companyPresenter(data);
	console.log('data: ', data);
	console.log(data);
	data.banks.map(bank => {
		switch(+bank.bank_id){
			case 1: {
				let options = {
					method: 'post',
					body: Object.assign({
						firstName: data.companyPersonName,
						middleName: data.companyPersonPatronymic,
						lastName: data.companyPersonSurname,
						phoneNumber: data.phone,
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
						modules.err(err);
					} else {
						modules.reducer.dispatch({
							type: "query",
							data: {
								query: "setApiResponce",
								values: [
									data.companyID,
									bank.bank_id,
									body.result ? body.result.applicationId : null,
									body.requestId,
									(body.result && (body.result.rejectCode || body.result.resultCode)) || body.errorMessage
								]
							}
						}).then(modules.then).catch(modules.err);
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
						phoneNumber: data.phone,
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
						modules.err(err);
					} else {
						modules.reducer.dispatch({
							type: "query",
							data: {
								query: "setApiResponce",
								values: [
									data.companyID,
									bank.bank_id,
									body.applicationId || null,
									body.requestId,
									(
										body.success ? "Заявка заведена" :
										(body.errorMessage || body.errorCode || body.resultCode)
									)
								]
							}
						}).then(modules.then).catch(modules.err);
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
								text: `Ф.И.О.: ${data.fio}\nТелефон: ${data.phone}\nНазвание: ${data.companyOrganizationName}\nИНН: ${data.companyInn}\nИдентификатор запроса: ${body.requestId}\nИдентификатор заявки: ${body.applicationId}\nКоментарий: ${data.companyComment}`
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
					body: `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:ru.psbank.webservices"><soapenv:Header /><soapenv:Body><urn:ProcessFormDataWithResponse><urn:formData><FormGuid>F3AA3CE8-3A9C-4EB9-8A57-902851E24AED</FormGuid><Data><Key>A8A548B6-0426-421E-887F-145013011E5A</Key><Value>${data.companyComment || ''}</Value></Data><Data><Key>F9C02B1A-6C91-4100-A0E4-769194159DF0</Key><Value>${data.templateTypeID == 11 ? 4 : 1}</Value></Data><Data><Key>54952415-C2E6-4E60-8173-59C8883443DA</Key><Value>${data.companyOrganizationName || ''}</Value></Data><Data><Key>A97B7E7A-55BE-47A5-85E8-F29604AFDD66</Key><Value>${data.companyInn || ''}</Value></Data><Data><Key>5C911979-769B-41B5-AE2F-C82743FAE71A</Key><Value>${data.companyPersonName || ''}</Value></Data><Data><Key>7277E008-8FC0-40AA-8B2E-10FB8F606E1F</Key><Value>${data.phone ? data.phone.replace("+7", "") : ''}</Value></Data><Data><Key>BAE4DCDE-537D-43A6-8F64-E96DF3E753B5</Key><Value>${data.companyEmail || ''}</Value></Data><Data><Key>116DD0EC-6C11-494E-8710-74F9342F4230</Key><Value>${bank.bankFilialRegionApiCode || ''}</Value></Data><Data><Key>35F9E22C-7C08-4B76-B4F3-1857E4546F5A</Key><Value>${bank.bankFilialApiCode || ''}</Value></Data><Data><Key>E1FBA727-ABB6-4A4D-9136-BB4E258508E9</Key><Value>1</Value></Data><Data><Key>57E8C256-F118-40F4-B7DC-611F2BBFA4C7</Key><Value>${applicationId || ""}</Value></Data><Data><Key>95FDCE7D-2ACB-4446-9705-7B9EDF41B6E9</Key><Value></Value></Data><Data><Key>F63886D3-ABB9-469D-AD35-35DDFEF989CB</Key><Value></Value></Data><Data><Key>7395BCA7-C8B4-405E-92DC-D70ACC0E19BC</Key><Value></Value></Data><Data><Key>D94C6B80-B6BC-4667-8A22-B2DE9CDE18A4</Key><Value></Value></Data><Data><Key>53C7EFE6-607F-4E4A-A028-90ADADD13343</Key><Value>PartnersEB</Value></Data><Data><Key>F3AC4BBE-AEE4-4B9D-8BB7-E0923FEC3905</Key><Value></Value></Data><Data><Key>0B76C7ED-D068-44F2-AFB1-591BD7F1489A</Key><Value>КалугаАстрал</Value></Data><Data><Key>9DB6E8B8-D503-4751-9C6A-6BABCA0FFDCE</Key><Value></Value></Data></urn:formData><urn:leadGenId>57E8C256-F118-40F4-B7DC-611F2BBFA4C7</urn:leadGenId></urn:ProcessFormDataWithResponse></soapenv:Body></soapenv:Envelope>`,
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
						modules.err(err);
					} else {
						let xmlResult = xml.parse(body),
								requestResult = xmlResult &&
												 xmlResult[2] &&
												 xmlResult[2].childNodes &&
												 xmlResult[2].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes[0].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[0].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes[0].childNodes[0].text || false,
								errorMessage = xmlResult &&
												 xmlResult[2] &&
												 xmlResult[2].childNodes &&
												 xmlResult[2].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[1] &&
												 xmlResult[2].childNodes[0].childNodes[1].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[1].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes[1].childNodes[0].text || false,
								requestStatus = xmlResult &&
												 xmlResult[2] &&
												 xmlResult[2].childNodes &&
												 xmlResult[2].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[2] &&
												 xmlResult[2].childNodes[0].childNodes[2].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[2].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes[2].childNodes[0].text || false,
								leadID = xmlResult &&
												 xmlResult[2] &&
												 xmlResult[2].childNodes &&
												 xmlResult[2].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[3] &&
												 xmlResult[2].childNodes[0].childNodes[3].childNodes &&
												 xmlResult[2].childNodes[0].childNodes[3].childNodes[0] &&
												 xmlResult[2].childNodes[0].childNodes[3].childNodes[0].text || false;
						modules.reducer.dispatch({
							type: "query",
							data: {
								query: "setApiResponce",
								values: [
									data.companyID,
									bank.bank_id,
									leadID || applicationId || null,
									null,
									errorMessage || requestStatus || requestResult || null
								]
							}
						}).then(modules.then).catch(modules.err);
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
						modules.err(err);
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
										contact_phone: data.phone || "",
										add_info: data.companyComment || "",
										agreement: 1,
										city: data.cityName || "",
										fio: data.fio
									})}`,
									url: modules.env.vtb.editAnketaUrl.replace("${id}", applicationId)
								};
						modules.log.writeLog("vtb", {
							type: "request",
							options
						});
						request(options, (err, res, body) => {
							if(err){
								modules.err(err);
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
											comment: data.companyComment || ""
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
											modules.err(err);
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
														bank.bank_id,
														applicationId || null,
														null,
														body.info || body.status_code || null
													]
												}
											}).then(modules.then).catch(modules.err);
										}
									});
								} else {
									modules.reducer.dispatch({
										type: "query",
										data: {
											query: "setApiResponce",
											values: [
												data.companyID,
												bank.bank_id,
												applicationId || null,
												null,
												body.info || body.status_code || null
											]
										}
									}).then(modules.then).catch(modules.err);
								}
							}
						});
					}
				});
			}
			break;
			case 6:
			case 8: {
				const options = {
					url: 'https://open.tochka.com:3000/rest/v1/request/new',
					method: 'POST',
					json: true,
					body: {
						token: modules.env.tochka.token,
						workMode: modules.env.tochka.workMode,
						request: {
							telephone: data.phone,
							name: data.companyOrganizationName,
							inn: data.companyInn,
							first_name: data.companyPersonName,
							last_name: data.companyPersonSurname,
							second_name: data.companyPersonPatronymic,
							comment: data.companyComment
						}
					}
				};

				if (data.company_person_sex) {
					options.body.request.sex = ['M', 'F'][data.company_person_sex - 1];
				}

				modules.log.writeLog("tochka", {
					type: "request",
					options
				});

				request(options, (err, response, body) => {

					modules.log.writeLog("tochka", {
						type: "responce",
						body
					});

					modules.reducer.dispatch({
						type: "query",
						data: {
							query: "setApiResponce",
							values: [
								data.companyID,
								bank.bank_id,
								null,
								null,
								((response.statusCode == 200 && body.data) ? "success" : (
									body.body ? body.body.join(', ') : response.statusCode
								))
							]
						}
					}).then(modules.then).catch(modules.err);
				});
			}
			break;
			case 7: {
				const options = {
						url: 'http://openpartners.ru/api/v2/request/add' + (modules.env.open.test ? '/test' : ''),
						method: 'POST',
						headers: {
							'Host': 'openpartners.ru',
							'X-Auth-Token': modules.env.open.token,
							'Content-type': 'multipart/form-data;'
						},
						form: {
							'full_name': data.fio,
							'inn': data.companyInn,
							'email': (data.email || "1@mail.ru"),
							'phone': data.phone,
							'city': data.cityName,
							'comment': "По API"
						}
				};

				modules.log.writeLog("open", {
					type: "request",
					options
				});

				request(options, (err, res, body) => {
						modules.log.writeLog("open", {
							type: "responce",
							body
						});

						if (err) {
							modules.err(err);
						} else {
							const req = JSON.parse(body);
							modules.reducer.dispatch({
								type: "query",
								data: {
									query: "setApiResponce",
									values: [
										data.companyID,
										bank.bank_id,
										null,
										null,
										(req.id ? "success" : req.error)
									]
								}
							}).then(modules.then).catch(modules.err);
						}
				});
			}
			break;
			case 12: {
				process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0';
				request({
					url: 'https://partner-lk.vbank.ru/lk-api/api/voz/departments/get',
					method: 'GET',
					json: true,
				}, (error, response, body) => {
					let idCity = null;

					modules.log.writeLog("voz", {
						type: "responce",
						body
					});

					!error && body.forEach(r => {
						if (data.regionName.toLowerCase() == r.name.toLowerCase()) {
							if(!r.cities.some(c => {
								if(c.name.toLowerCase() == data.cityName.toLowerCase()) {
									idCity = c.code;
									return true;
								}
							})) {
								idCity = r.cities[0].code;
							}
						}
					});
					if (idCity) {
						var options = {
							url: 'https://partner-lk.vbank.ru/lk-api/api/voz/agentapi/document/modification',
							method: 'POST',
							headers: {
								'Authorization': 'Basic ' + Buffer(modules.env.voz.apiId + ":" + modules.env.voz.key).toString("base64")
							},
							json: true,
							body: {
								tin: data.companyInn,
								phone: data.phone,
								fullName: data.fio,
								company: data.companyOrganizationName,
								email: "123@123.ru",
								idCity: idCity
							}

						};

						modules.log.writeLog("voz", {
							type: "request",
							options
						});

						request(options, (error, response, body) => {
							modules.log.writeLog("voz", {
								type: "responce",
								body
							});
							modules.reducer.dispatch({
								type: "query",
								data: {
									query: "setApiResponce",
									values: [
										data.companyID,
										bank.bank_id,
										null,
										null,
										((error || body.errorText) ? body.errorText : "success")
									]
								}
							}).then(modules.then).catch(modules.err);
						});
					}
				});
			}
			break;
			case 5:
			case 9:
			case 10: {
				const banksKey= {
					5: "alfa",
					// 6: "sberbank",
					// 7: "open",
					// 8: "tochka",
					9: "raiffaisen",
					10: "ubrr"
				};
				let options = {
					method: "put",
					body: Object.assign({
						inn: data.companyInn,
						customer: data.companyOrganizationName,
						address: data.cityName,
						ceo: data.fio,
						mail: data.companyEmail || "",
						phone: data.phone
					}, modules.env.partnerka.body, modules.env[banksKey[+bank.bank_id]].body),
					url: modules.env.partnerka.applicationUrl,
					json: true
				};
				options.body.hash = `${transformCyrillicToUnicode(JSON.stringify(options.body))}${modules.env.partnerka.token}`;
				options.body.hash = crypto.createHash("sha512").update(options.body.hash, "utf8").digest("hex");
				modules.log.writeLog(banksKey[+bank.bank_id], {
					type: "request",
					options
				});
				request(options, (err, res, body) => {
					if(err){
						modules.err(err);
					} else {
						typeof body == "string" && (body = jsonConvertor(body));
						modules.log.writeLog(banksKey[+bank.bank_id], {
							type: "responce",
							body
						});
						modules.reducer.dispatch({
							type: "query",
							data: {
								query: "setApiResponce",
								values: [
									data.companyID,
									bank.bank_id,
									body.nid || null,
									null,
									body.success || (typeof body == "string" && body) || (typeof body == "object" && !body.hasOwnProperty("nid") && Object.keys(body).length > 0 && Object.keys(body).map(i => body[i]).join(" ")) || null
								]
							}
						}).then(modules.then).catch(modules.err);
					}
				});
			}
			break;
		}
	});
}
