import { Map } from 'immutable';
export default (store = Map(), action) => {
	switch (action.type) {
		case "changeMenuState": {
			let menuSwitch = store.get("menuSwitch") || false;
			return store.set("menuSwitch", !menuSwitch);
		}
		case "changePage": return store.set("page", action.data.page);
		default: return store;
	}
}