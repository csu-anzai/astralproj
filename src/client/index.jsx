import { render } from 'react-dom';
import * as React from 'react';
import { createHashHistory } from 'history';
import { syncHistory, routeReducer, push } from 'react-router-redux';
import { applyMiddleware, createStore, combineReducers } from 'redux';
import { Provider } from 'react-redux';
import { Router } from 'react-router';
import Reducer from './reducer';
import Main from './routes';
import io from 'socket.io-client';
import env from './../env.json';
const history = createHashHistory();
const middleware = syncHistory(history);
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
	routing: routeReducer
}), applyMiddleware(middleware, socketMiddleware(socket)));
socket.on("message", data => {
	for(let i = 0; i < data.length; i++) {
		if(data[i].type != "redirect"){
			Store.dispatch(data[i]);
		} else {
			Store.dispatch(push(data[i].data.url));
		}
	}
});
const hash = window.location.hash.split("#").join("");
localStorage.setItem("hash", hash);
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
