const JE = require('json-xlsx');
module.exports = modules => (resolve, reject, data) => {
	const je = new JE({tmpDir: __dirname + '/files/'});
	je.write(data, (err, filepath) => {
    console.log(filepath);
	});
}

/*{
  "name": "sheetname",
  "data": [
    [
      1231,
      4561,
      7891
    ],
    [
      1232,
      4562,
      7893
    ]
  ]
}*/