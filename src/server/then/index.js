let err = require("./../err");
let then = (reducer, data) => {
	err = err.bind(this, reducer);
	(data && data[2] && data[2][0] && data[2][0].a && (data = data[2][0].a)) ||
	(data && data[0] && data[0].a && (data = data[0].a)) || (data = false);
	if (data){
		let arr = JSON.parse(data);
		for (let i = 0; i < arr.length; i++){
			let obj = arr[i];
			reducer.dispatch(obj).then(then.bind(this, reducer)).catch(err);
		}
	}
}
module.exports = then;