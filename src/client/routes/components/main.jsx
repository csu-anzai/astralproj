import React from 'react';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import Header from './header';
import Menu from './menu';
import { Route, Switch, Redirect } from "react-router";
import { push } from "react-router-redux";
import Login from './../routes/login';
import ForgotPassword from './../routes/forgotPassword';
export default class Main extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			hash: window.location.hash.split("#").join("")
		}
	}
	render(){	
		return <MuiThemeProvider>
			<div>
				{
					(this.props.state.auth && (this.state.hash != "/login" || this.state.hash != "/forgotPassword")) &&
					<div> 
						<Menu/>
						<Header/>
					</div> || ""
				}
				{
					this.props.state.auth ? this.props.childrens : <Switch>
						<Route path = "/login" component = {Login}/>
						<Route path = "/forgotPassword" component = {ForgotPassword}/>
						<Redirect to = "/login" />
					</Switch>
				}
			</div>
		</MuiThemeProvider>
	}
}