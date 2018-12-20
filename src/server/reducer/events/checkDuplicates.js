const request = require("request");
module.exports = modules => (resolve, reject, data) => {
	let companiesLength = data.companies.length,
			count = 100,
			integers = parseInt(companiesLength/count),
			remainder = integers > 0 ? (companiesLength % count) : 0;
	let companies = [];
	if(integers == 0){
		companies = [data.companies.map(company => company.company_id)];
	} else {
		for(let i = 0; i < integers; i++){
			let companiesArr = [];
			for(let j = 0; j < count; j++){
				companiesArr.push(data.companies[(i*count)+j].company_id);
			}
			companies.push(companiesArr);
		}
		if(remainder > 0){
			let companiesArr = [];
			for(let i = 0; i < remainder; i++){
				companiesArr.push(data.companies[(integers*count)+i].company_id);
			}
			companies.push(companiesArr);
		}
	}
	modules.log.writeLog("system", {
		type: "checkDuplicates",
		data
	});
	companies && data.companies.length > 0 && Promise.all(data.companies.map(company =>
		Promise.all([
			new Promise((resolve, reject) => {
				request({
					url: modules.env.tinkoff.checkInnUrl,
					json: true,
					body: { 
						fields: { 
							inn: company.company_inn
						}
			   	}
				}, (err, responce, body) => {
						err ? reject(err) : resolve(body.result);
				});
			})
		]) 
	)).then(responce => {
		modules.log.writeLog("system", {
			type: "checkDuplicatesResponce",
			responce
		});
		const companies = responce.map((arr, key) => ({
			company_id: data.companies[key].company_id,
			banks: arr.map((item, key) => ({
				bank_id: +key + 1,
				status_text: item 
			}))
		}));
		modules.reducer.dispatch({
			type: "query",
			data: {
				query: "setDuplicates",
				values: [
					data.user_id,
					JSON.stringify(companies)
				]
			}
		}).then(resolve).catch(reject);
	}).catch(reject);
}