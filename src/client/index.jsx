import { render } from 'react-dom';
import * as React from 'react';
import { createHashHistory } from 'history';
import { syncHistoryWithStore, routerReducer, push, routerMiddleware } from 'react-router-redux';
import { applyMiddleware, createStore, combineReducers } from 'redux';
import { Provider } from 'react-redux';
import { Router } from 'react-router';
import Reducer from './reducer';
import Main from './routes';
const history = createHashHistory();
const middleware = routerMiddleware(history);
const Store = createStore(combineReducers({
	app: Reducer,
	routing: routerReducer
}), applyMiddleware(middleware));
const historySync = syncHistoryWithStore(history, Store);
window.addEventListener("DOMContentLoaded", () => {
	render(
		<Provider store = { Store }>
			<Router history = { historySync }>
				{Main}
			</Router>
		</Provider>,
		document.getElementById("app")
	);
});
