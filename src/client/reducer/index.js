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
		case "updateArray": {			
			let arr = store.get(action.data.name);
			let index = arr.findIndex(item => {
				item = item.toJS();
				let keys = Object.keys(action.data.search);
				return item[keys[0]] && item[keys[0]] == action.data.search[keys[0]];
			});
			if (index != -1) {
				arr = arr.set(index, arr.get(index).merge(fromJS(action.data.values)));
				store = store.set(action.data.name, arr);
			}
			return store;
		}
		case "save": {
			let keys = Object.keys(action.data);
			let app = localStorage.getItem("app") || {};
			typeof app == "string" && (app = JSON.parse(app));
			for(let key in keys){
				app[keys[key]] = action.data[keys[key]];
			}
			localStorage.setItem("app", JSON.stringify(app));
			return store;
		}
		case "deleteFromArray": {
			let list = store.get(action.data.name);
			let arr = list.toJS();
			for (let i = 0; i < arr.length; i++) {
				let item = arr[i];
				if(action.data.searchValues.indexOf(item[action.data.searchParam]) > -1) {
					let index = list.findIndex(li => li.get(action.data.searchParam) == item[action.data.searchParam]);
					list = list.delete(index);
				}
			}
			store = store.set(action.data.name, list);
			return store;
		}
		default: return store;
	}
}