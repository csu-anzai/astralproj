import React from 'react';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import Header from './header';
import Menu from './menu';
import { push } from 'react-router-redux';
export default class Main extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			hash: localStorage.getItem("hash")
		}
	}
	componentDidMount(){
		if (this.props.state.auth && this.state.hash){
			this.props.dispatch(push(this.state.hash));
			localStorage.removeItem("hash");
		}
	}
	render(){	
		return <MuiThemeProvider>
			<div>
				{
					this.props.state.auth &&
					<div> 
						<Menu/>
						<Header/>
					</div> || ""
				}
				{
					this.props.childrens
				}
			</div>
		</MuiThemeProvider>
	}
}