import { render } from 'react-dom';
import * as React from 'react';
import { createHashHistory } from 'history';
import { syncHistoryWithStore, routerReducer, push, routerMiddleware } from 'react-router-redux';
import { applyMiddleware, createStore, combineReducers } from 'redux';
import { Provider } from 'react-redux';
import { Router } from 'react-router';
import Reducer from './reducer';
import Main from './routes';
import io from 'socket.io-client';
import env from './../env.json';
const history = createHashHistory();
const middleware = routerMiddleware(history);
const socket = io(`${env.ws.location}:${env.ws.port}`);
const socketMiddleware = socket => store => next => action => {
	if (action.socket) {
		delete(action.socket);
		socket.send(action);
	}
	return next(action);
}
const Store = createStore(combineReducers({
	app: Reducer,
	routing: routerReducer
}), applyMiddleware(middleware, socketMiddleware(socket)));
socket.on("message", data => {
	for(let i = 0; i < data.length; i++) {
		if(data[i].type != "redirect"){
			Store.dispatch(data[i]);
		} else {
			Store.dispatch(push(data[i].data.page));
		}
	}
});
const hash = window.location.hash.split("#").join("");
localStorage.setItem("hash", hash);
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
