import Order from './order';
import Login from './login';
import React from 'react';
import { Route, Switch } from 'react-router';
const Childrens = <Switch>
	<Route path = "/order" component = {Order}/>
	<Route path = "/login" component = {Login}/>
</Switch>
export default Childrens;