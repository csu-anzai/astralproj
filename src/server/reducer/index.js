const fs = require('fs');
module.exports = class App {
	constructor(){
		this.eventsPaths = fs.readdirSync(`${__dirname}/events/`);
		this.events = {};
		this.modules = {};
	}
	initEvents(modules = {}){
		Object.keys(modules).length > 0 && (this.modules = Object.assign(this.modules, modules));
		for(let i = 0; i < this.eventsPaths.length; i++){
			let fileName = this.eventsPaths[i].match(/([aA-zZ]*)\.js/);
			fileName && (this.events[fileName[1]] = require(`${__dirname}/events/${this.eventsPaths[i]}`)(this.modules));
		}
	}
	dispatch(event){
		return new Promise((resolve, reject) => {
			if(this.events[event.type]){
				if(event.data.timeout && event.data.timeout > 0){
					setTimeout(this.events[event.type].bind(this, resolve, reject, event.data), event.data.timeout);
				} else {
					this.events[event.type](resolve, reject, event.data);
				}
			} else {
				reject(`event ${event.type} not found`);
			}
		});
	}
}