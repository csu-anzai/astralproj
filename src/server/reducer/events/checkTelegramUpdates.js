module.exports = modules => (resolve, reject, data) => {
	modules.telegram.getUpdates(data.offset, data.limit, data.timeout, data.allowed_updates).then(responce => {
		if(responce.ok == true && responce.result && responce.result.length > 0){
			responce.result.filter(item => item.hasOwnProperty("message") || item.hasOwnProperty("edited_message")).forEach(item => {
				itemObj = item.message || item.edited_message;
				if(itemObj && itemObj.chat && itemObj.chat.id){
					modules.reducer.dispatch({
						type: "query",
						data: {
							query: "confirmTelegram",
							values: [
								itemObj.chat.id
							]
						}
					}).then(modules.then).catch(modules.err);
				} else {
					reject("Ошибка при обработке сообщений из телеграмма");
				}
			});
			modules.reducer.dispatch({
				type: "checkTelegramUpdates",
				data: {
					offset: parseInt(responce.result[responce.result.length - 1].update_id) + 1
				}
			}).then(resolve).catch(reject);
		} else {
			setTimeout(() => {
				modules.reducer.dispatch({
					type: "checkTelegramUpdates",
					data: {

					}
				}).then(resolve).catch(reject);
			}, 3000);
		}
	}).catch(err => {
		setTimeout(() => {
			modules.reducer.dispatch({
				type: "checkTelegramUpdates",
				data: {

				}
			}).then(modules.then).catch(modules.err);
		}, 3000);
		reject({message: "ошибка в обновлении телеграма", err});
	});
}
