import React from 'react';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import Header from './header';
import Menu from './menu';
import { Route } from "react-router";
import { push } from "react-router-redux";
import Login from './../routes/login/';
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
					(this.props.state.auth && this.state.hash != "/login") &&
					<div> 
						<Menu/>
						<Header/>
					</div>
				}
				{
					this.props.state.auth ? this.props.childrens : <Login />
				}
			</div>
		</MuiThemeProvider>
	}
}