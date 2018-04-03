import Tinkoff from './tinkoff';
import React from 'react';
import { Route, Switch, Redirect } from 'react-router';
const Childrens = <Switch>
	<Route path = "/tinkoff" component = {Tinkoff}/>
	<Redirect to = "/tinkoff"/>
</Switch>;
export default Childrens;