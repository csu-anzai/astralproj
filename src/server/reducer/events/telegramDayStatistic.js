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
				message += `${item.user_name}:\n--\nобработано всего лидов - ${item.types.map(type => type.count).reduce((before, after) => before + after)};\n${item.types.map(type => `${type.type_name} – ${type.count}`).join("\n")}\n--\n${item.banks.map(bank => `${bank.bank_name} – ${bank.count}`).join("\n")}\n\n`;
			});
		} else {
			message = "Сегодня нет обработанных компаний";
		}
		modules.log.writeLog("system", message);
		modules.reducer.dispatch({
			type: "print",
			data: {
				message,
				telegram: 1
			}
		}).then(resolve).catch(reject);
	}).catch(reject);
}