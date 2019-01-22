module.exports = modules => (resolve, reject, data) => {
	let promises = [];
	for (let i = 0; i < data.companies.length; i++) {
		let company = data.companies[i];
		promises.push(modules.dadata.getCompanyInformation(company.company_inn));
	}
	Promise.all(promises).then(responce => {
		let companiesInfo = [];
		for(let i = 0; i < responce.length; i++){
			let company = data.companies[i],
					city_name = responce[i].suggestions[0].data.address &&
											responce[i].suggestions[0].data.address.data &&
											responce[i].suggestions[0].data.address.data.city ||
											undefined;
			!!city_name && companiesInfo.push({
				company_id: company.company_id,
				city_name
			});
		}
		modules.reducer.dispatch({
			type: "query",
			data: {
				query: "setCompanyInformationResponce",
				values: [
					JSON.stringify(companiesInfo)
				]
			}
		});
	});
}