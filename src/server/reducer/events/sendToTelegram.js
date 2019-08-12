module.exports = modules => (resolve, reject, data) => {
	for(let i = 0; i < data.chats.length; i++){
		let chat = data.chats[i];
		modules.telegram.sendMessage(chat, data.message).then(i == data.chats.length - 1 ? resolve : modules.then).catch(i == data.chats.length - 1 ? reject : modules.err);
	}
}