module.exports = modules => (resolve, reject, data) => {
	modules.telegram.sendMessage(data.chatID, data.message).then(resolve).catch(reject);
}