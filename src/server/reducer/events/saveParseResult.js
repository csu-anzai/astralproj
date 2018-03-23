module.exports = modules => (resolve, reject, data) => {
	let keysLength = Object.keys(data).length,
			queries = [];
	if(keysLength > 501){
		let columns = data.columns;
		delete(data.columns);
		let iterations = Math.floor((keysLength - 1) / 500),
				remainder = (keysLength - 1) % 500;
		for(let i = 0; i < iterations; i++) {
			queries.push({
				columns: columns
			});
			for(let j = 0; j < 500; j++){
				queries[i]["r"+(j+1)] = data["r"+((j+1)+(500*(i+1)))];
			}
		}
	}
	console.log(queries);
	//data = JSON.stringify(data);
	/*modules.mysql.query(
		`SET @responce = JSON_ARRAY(); CALL newCompanies('${data}', @responce); SELECT @responce AS a`,
		(err, responce) => {
			err ? reject(err) : resolve(responce);
		}
	);*/
}