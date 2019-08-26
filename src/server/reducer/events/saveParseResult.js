module.exports = modules => (resolve, reject, data) => {
	let		queries = [],
				remainder = 0;
	const part = modules.env.parser.part,
				keysLength = Object.keys(data).length - 1;
	if (keysLength > 0){
		const columns = data.columns;
		delete(data.columns);
		const integers = Math.floor(keysLength/part);
		remainder = keysLength % part;
		if (integers == 0) {
			data.columns = columns;
			queries.push(data);
		} else {
			const keys = Object.keys(data);
			for (let i = 0; i < integers; i++) {
				queries[i] = { columns };
				let object = queries[i];
				for (let j = 0; j < part; j++) {
					let key = keys[part * i + j];
					object[`r${j+1}`] = data[key];
				}
			}
			if (remainder > 0) {
				queries.push({
					columns
				});
				let object = queries[queries.length - 1];
				for (let i = 0; i < remainder; i++) {
					let key = keys[integers * part + i];
					object[`r${i+2}`] = data[key];
				}
			}
		}
		for (let i = 0; i < queries.length; i++) {
			let query = queries[i];
			query = JSON.stringify(query, (propKey, value) => {
				return typeof value != "string" ? value : value.replace(/\"/g, "").replace(/\//g, "");
			});
			modules.reducer.dispatch({
				type: "procedure",
				data: {
					query: "newCompanies",
					values: [
						query,
						(i == (queries.length - 1) ? 1 : 0)
					]
				}
			}).then(resolve).catch(reject);
		}
	} else {
		console.log("There are no entries in the file");
	}
}
