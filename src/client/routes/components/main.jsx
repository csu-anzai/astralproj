import React from 'react';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import Header from './header';
import Menu from './menu';
export default class Main extends React.Component {
	render(){
		return <MuiThemeProvider>
			<div>
				<Menu/>
				<Header/>
				{this.props.childrens}
			</div>
		</MuiThemeProvider>
	}
}