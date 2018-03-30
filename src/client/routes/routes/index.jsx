import Tinkoff from './tinkoff';
import Login from './login';
import React from 'react';
import { Route, Switch, Redirect } from 'react-router';
const Childrens = <Switch>
	<Route path = "/tinkoff" component = {Tinkoff}/>
	<Route exact path = "/" component = {Tinkoff}/>
	<Route exact path = "/login" component = {Login}/>
</Switch>;
export default Childrens;