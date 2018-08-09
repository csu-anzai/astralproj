const JE = require('json-xlsx');
module.exports = modules => (resolve, reject, data) => {
	const je = new JE({tmpDir: __dirname + '/../../express' + modules.env.express.staticPath});
	je.write({name: data.name, data: data.data}, (err, filepath) => {
    modules.log.writeLog("files", {
        type: "createFile",
        filepath
    });
    if (err) {
    	reject(err);
    } else {
    	let fileName = filepath.match(".*/(.*\.xlsx)")[1];
			filepath = `${modules.env.ws.location}:${modules.env.ws.port}/${fileName}`;
    	modules.reducer.dispatch({
    		type: "query",
    		data: {
    			query: "updateFileName",
    			values: [
    				data.fileID,
    				filepath
    			]
    		}
    	}).then(resolve).catch(reject);
    }
	});
}