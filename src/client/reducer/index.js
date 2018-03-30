import { Map, fromJS } from 'immutable';
export default (store = Map(), action) => {
	switch (action.type) {
		case "changeMenuState": {
			let menuSwitch = store.get("menuSwitch") || false;
			return store.set("menuSwitch", !menuSwitch);
		}
		case "changePage": return store.set("page", action.data.page);
		case "set": return fromJS(action.data);
		case "merge": return store.merge(fromJS(action.data));
		case "mergeDeep": return store.mergeDeep(fromJS(action.data));
		case "updateArray":			
			let arr = store.get(action.data.name);
			let index = arr.indexOf(fromJS(action.data.search));
			if (index != -1) {
				arr = arr.set(index, arr.get(index).merge(fromJS(action.data.values)));
				store = store.set(action.data.name, arr);
			}
			return store;
		case "save": 
			let keys = Object.keys(action.data);
			let app = localStorage.getItem("app") || {};
			typeof app == "string" && (app = JSON.parse(app));
			for(let key in keys){
				app[keys[key]] = action.data[keys[key]];
			}
			localStorage.setItem("app", JSON.stringify(app));
			return store;
		default: return store;
	}
}