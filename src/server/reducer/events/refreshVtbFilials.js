const request = require("request");
module.exports = modules => (resolve, reject, data) => {
	let firstQuery = true;
	const createNewTimeout = () => {
		const processNextFilials = (start, limit, total) => {
			let options = {
				url: `${modules.env.vtb.filialsUrl}?start=${start}&limit=${limit}`,
				method: "post",
				headers: {
					Token: modules.vtb.getToken()
				}
			};
			request(options, (err, res, body) => {
				if (err) {
					reject(err);
				} else {
					typeof body == "string" && (body = JSON.parse(body));
					if (!body || !body.branch_list || !body.branch_list.list || body.branch_list.list.length <= 0) {
						reject(`Нет листа филиалов ВТБ на определенной итерации: start ${start}, limit ${limit}, total ${total}`);
					} else {
						let newStart = start + limit;
						deployFilials(body.branch_list.list, newStart >= total);
						newStart < total && processNextFilials(newStart, limit, total);
					}
				}
			});
		};
		const deployFilials = (filials, end) => {
			filials = filials.filter(filial => filial.name.value != "Колл-центр");
			if (filials.length > 0) {
				modules.reducer.dispatch({
					type: "query",
					data: {
						query: "setBankFilials",
						values: [
							4,
							JSON.stringify(filials.map(i => ({
								city_name: i.city_id.value,
								bank_filial_api_code: i.id.value,
								bank_filial_name: i.name.value,
								region_code: i.region.value
							}))),
							firstQuery
						]
					}
				}).then(end ? resolve : modules.then).catch(reject);
				firstQuery && (firstQuery = false);
			}
		};
		setTimeout(() => {
			if(!modules.vtb.getToken()){
				createNewTimeout();
			} else {
				let start = 1;
				let options = {
					url: `${modules.env.vtb.filialsUrl}?start=${start}&limit=100`,
					method: "post",
					headers: {
						Token: modules.vtb.getToken()
					}
				};
				request(options, (err, res, body) => {
					if (err) {
						reject(err);
					} else {
						typeof body == "string" && (body = JSON.parse(body));
						if (!body || !body.branch_list || !body.branch_list.list || body.branch_list.list.length <= 0) {
							reject("Нет листа филиалов ВТБ");
						} else {
							let allFilialsCount = +body.branch_list.total;
							let maxListLength = body.branch_list.list.length;
							deployFilials(body.branch_list.list, maxListLength >= allFilialsCount);
							if (maxListLength < allFilialsCount) {
								processNextFilials(maxListLength + start, maxListLength, allFilialsCount);
							}
						}
					}
				});
			}
		}, 1000);
	};
	createNewTimeout();
}