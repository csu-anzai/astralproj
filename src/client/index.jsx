import { render } from 'react-dom';
import * as React from 'react';
import { createHashHistory } from 'history';
import { syncHistoryWithStore, routerReducer, push } from 'react-router-redux';
import { applyMiddleware, createStore, combineReducers } from 'redux';
import { Provider } from 'react-redux';
import { Router} from 'react-router';
import Reducer from './reducer';
import Main from './routes';
const Store = createStore(combineReducers({
	app: Reducer,
	routing: routerReducer
}));
const history = syncHistoryWithStore(createHashHistory(), Store);
window.addEventListener("DOMContentLoaded", () => {
	render(
		<Provider store = { Store }>
			<Router history = { history }>
				{Main}
			</Router>
		</Provider>,
		document.getElementById("app")
	);
});
