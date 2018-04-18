const JE = require('json-xlsx');
module.exports = modules => (resolve, reject, data) => {
	var je = new JE({tmpDir: __dirname + '/files/'});
	je.write(data, (err, filepath) => {
    console.log(filepath)
	});
}