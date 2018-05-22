const request = require('request'),
			crypto = require('crypto');
module.exports = modules => (resolve, reject, data) => {
	if(data && data.options && data.method && data.type) {
		const sortOptionKeys = Object.keys(data.options).sort(),
					queryString = sortOptionKeys.map(option => `${option}=${data.options[option]}`).join("&"),
					sign = Buffer.from(
						crypto.createHmac('sha1', modules.env.zadarma.secret).update(`/${modules.env.zadarma.version}/${data.method}/${queryString}${crypto.createHash("md5").update(queryString).digest("hex")}`).digest('hex')
					).toString("base64");
		const options = {
			method: data.type,
			url: `${modules.env.zadarma.url}/${modules.env.zadarma.version}/${data.method}/${data.type.toLowerCase() == "get" ? "?"+queryString : ""}`,
			headers: {
				'Authorization': `${modules.env.zadarma.key}:${sign}`
			}
		};
		request(options, (error, response, body) => {
			error ? 
				console.log(error) :
				console.log(body);
		});
	}
}