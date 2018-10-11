const request = require('request'),
			xml = require("xml-parse");
module.exports = modules => (resolve, reject, data) => {
	let template = {
		firstName: data.companyPersonName,
		middleName: data.companyPersonPatronymic,
		lastName: data.companyPersonSurname,
		phoneNumber: data.companyPhone,
		product: "РКО",
		companyName: data.companyOrganizationName
	};
	let bankName = ["tinkoff", "modul", "promsvyaz"][data.bankID - 1];
	let body = (data.bankID == 1 || data.bankID == 2) ? 
		Object.assign(data.bankID == 1 ? {
			source: "Федеральные партнеры",
			subsource: "API",
			innOrOgrn: data.companyInn || data.companyOgrn,
			comment: data.companyComment
		} : data.bankID == 2 && {
			[data.companyInn ? "inn" : "ogrn"]: data.companyInn || data.companyOgrn
		}, modules.env[bankName].body, template) : 
		`<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:ru.psbank.webservices"><soapenv:Header /><soapenv:Body><urn:ProcessFormDataWithResponse><urn:formData><FormGuid>F3AA3CE8-3A9C-4EB9-8A57-902851E24AED</FormGuid><Data><Key>A8A548B6-0426-421E-887F-145013011E5A</Key><Value>${data.companyComment}</Value></Data><Data><Key>F9C02B1A-6C91-4100-A0E4-769194159DF0</Key><Value>${data.templateTypeID == 11 ? 4 : 1}</Value></Data><Data><Key>54952415-C2E6-4E60-8173-59C8883443DA</Key><Value>${data.companyOrganizationName}</Value></Data><Data><Key>A97B7E7A-55BE-47A5-85E8-F29604AFDD66</Key><Value>${data.companyInn}</Value></Data><Data><Key>5C911979-769B-41B5-AE2F-C82743FAE71A</Key><Value>${data.companyPersonName}</Value></Data><Data><Key>7277E008-8FC0-40AA-8B2E-10FB8F606E1F</Key><Value>${data.companyPhone.replace("+7", "")}</Value></Data><Data><Key>BAE4DCDE-537D-43A6-8F64-E96DF3E753B5</Key><Value>${data.companyEmail}</Value></Data><Data><Key>116DD0EC-6C11-494E-8710-74F9342F4230</Key><Value>${data.psbRegionCode}</Value></Data><Data><Key>35F9E22C-7C08-4B76-B4F3-1857E4546F5A</Key><Value>${data.psbFilialCode}</Value></Data><Data><Key>E1FBA727-ABB6-4A4D-9136-BB4E258508E9</Key><Value>1</Value></Data><Data><Key>57E8C256-F118-40F4-B7DC-611F2BBFA4C7</Key><Value>${"1".repeat(Math.floor(Math.random()*3)+10).split("").map(() => Math.floor(Math.random()*10)).join("")}</Value></Data><Data><Key>95FDCE7D-2ACB-4446-9705-7B9EDF41B6E9</Key><Value></Value></Data><Data><Key>F63886D3-ABB9-469D-AD35-35DDFEF989CB</Key><Value></Value></Data><Data><Key>7395BCA7-C8B4-405E-92DC-D70ACC0E19BC</Key><Value></Value></Data><Data><Key>D94C6B80-B6BC-4667-8A22-B2DE9CDE18A4</Key><Value></Value></Data><Data><Key>53C7EFE6-607F-4E4A-A028-90ADADD13343</Key><Value>PartnersEB</Value></Data><Data><Key>F3AC4BBE-AEE4-4B9D-8BB7-E0923FEC3905</Key><Value></Value></Data><Data><Key>0B76C7ED-D068-44F2-AFB1-591BD7F1489A</Key><Value>КалугаАстрал</Value></Data><Data><Key>9DB6E8B8-D503-4751-9C6A-6BABCA0FFDCE</Key><Value></Value></Data></urn:formData><urn:leadGenId>57E8C256-F118-40F4-B7DC-611F2BBFA4C7</urn:leadGenId></urn:ProcessFormDataWithResponse></soapenv:Body></soapenv:Envelope>`;
	let headers = {
		"Authorization": "Basic S2FsdWdhQXN0cmFsOk5hVHI2R216R0dQbg==",
		"Content-Type": "text/xml; charset=utf-8"
	};
	var options = {
		method: 'post',
		body,
		url: "https://www.psbank.ru/psbservices/FormFillerWithAuth/FormFiller.asmx",
		headers
	};
	if(data.bankID != 3){
		var options2 = {
			method: 'post',
			body,
			url: modules.env[bankName].applicationUrl,
			json: true
		};
	}
	modules.log.writeLog(bankName, {
		type: "request",
		options: data.bankID == 3 ? options : options2
	});
	request(data.bankID == 3 ? options : options2, (err, res, body) => {
		if(err){
			reject(err);
		} else {
			let xmlResult, answer;
			if(data.bankID == 3){
				xmlResult = xml.parse(body);
				answer = xmlResult[2].childNodes[0].childNodes[2].childNodes[0].text;
			}
			modules.reducer.dispatch({
				type: "query",
				data: {
					query: "setApiResponce",
					values: [
						data.companyID,
						data.bankID != 3 ? ((body.hasOwnProperty("result") && body.result.hasOwnProperty("applicationId")) ?
							body.result.applicationId :
							body.applicationId || "false") : "123",
						data.bankID != 3 ? body.requestId : null,
						data.bankID != 3 ? (body.success ? 1 : 0) : 1
					]
				}
			}).then(resolve).catch(reject);
		}
		modules.log.writeLog(bankName, {
			type: "responce",
			body
		});
	});
}