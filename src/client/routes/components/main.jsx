import React from 'react';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import Header from './header';
import Menu from './menu';
export default class Main extends React.Component {
	render(){
		return <MuiThemeProvider>
			<div>
				{
					this.props.routing.locationBeforeTransitions == null ||
					this.props.routing.locationBeforeTransitions.hasOwnProperty("pathname") &&
					this.props.routing.locationBeforeTransitions.pathname != "/login" &&
					<div> 
						<Menu/>
						<Header/>
					</div>
				}
				{this.props.childrens}
			</div>
		</MuiThemeProvider>
	}
}