const fs = require("fs");
module.exports = modules => (resolve, reject, data) => {
	if(data.from && data.to && data.fileName){
		const from = `${__dirname}/../../${data.from}/${data.fileName}`,
					to = `${__dirname}/../../${data.to}/${data.fileName}`;
		fs.rename(from, to, err => {
			if(err){
				reject(err);
			} else {
				console.log(`файл перемещен успешно из ${from} в ${to}`);
			}
		});
	}
}