module.exports = modules => (resolve, reject, data) => {
	modules.reducer.dispatch({
		type: "query",
		data: {
			query: "getDayStatistic",
			values: [

			]
		}
	}).then(responce => {
		responce = responce && responce[0] && responce[0].a;
		responce && typeof responce == "string" && (responce = JSON.parse(responce));
		let message = "";
		if(responce && responce.length > 0){
			message = "Статистика по обработке компаний за день:\n\n";
			responce.forEach(item => {
				message += `${item.user_name}: обработано всего - ${item.all_companies}, из них успешных заявок - ${item.api_success_all};\n`;
			});
		} else {
			message = "Сегодня нет обработанных компаний";
		}
		modules.reducer.dispatch({
			type: "print",
			data: {
				message,
				telegram: 1
			}
		}).then(resolve).catch(reject);
	}).catch(reject);
}