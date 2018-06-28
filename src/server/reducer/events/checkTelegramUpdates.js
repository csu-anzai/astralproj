module.exports = modules => (resolve, reject, data) => {
	modules.telegram.getUpdates(data.offset, data.limit, data.timeout, data.allowed_updates).then(responce => {
		console.log(data.offset);
		if(responce.ok == true && responce.result && responce.result.length > 0){
			responce.result.filter(item => item.hasOwnProperty("message") || item.hasOwnProperty("edited_message")).forEach(item => {
				itemObj = item.message || item.edited_message;
				if(itemObj && itemObj.chat && itemObj.chat.id && itemObj.text){
					if(itemObj.text.length == 32){
						modules.reducer.dispatch({
							type: "query",
							data: {
								query: "confirmTelegram",
								values: [
									itemObj.text,
									itemObj.chat.id
								]
							}
						}).then(resolve).catch(reject);
					} else {
						modules.reducer.dispatch({
							type: "sendToTelegram",
							data: {
								chatID: itemObj.chat.id,
								message: "Код авторизации не валидный, измените ваше сообщение либо отправьте новое с верным кодом!"
							}
						}).then(responce => {
							if(responce.ok == true){
								modules.reducer.dispatch({
									type: "checkTelegramUpdates",
									data: {
										offset: item.update_id
									}
								}).then(resolve).catch(reject);
							} else {
								reject(responce);
							}
						}).catch(reject);
					}
				} else {
					reject("Ошибка при обработке сообщений из телеграмма\n");
				}
			});
		}
	}).catch(reject);
}