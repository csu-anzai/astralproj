import React from 'react';
import AppBar from 'material-ui/AppBar';
import { connect } from 'react-redux';
import IconButton from 'material-ui/IconButton';
import ExitToApp from 'material-ui/svg-icons/action/exit-to-app';
import Dialog from 'material-ui/Dialog';
import FlatButton from 'material-ui/FlatButton';
class Header extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			open: false
		}
		this.menu = this.menu.bind(this);
		this.logout = this.logout.bind(this);
	}
	dialog(bool){
		this.setState({
			open: bool
		});
	}
	menu(){
		this.props.dispatch({
			type: "changeMenuState"
		})
	}
	logout(){
		this.props.dispatch({
			type: "query",
    	socket: true,
    	data: {
    		query: "logout",
    		values: [
    			this.props.state.connectionHash
    		]
    	}
		});
	}
	render(){
		return <div>
			<Dialog
				actions = {[
					<FlatButton
		        label="Выйти"
		        primary={true}
		        onClick={this.logout}
		      />,
		      <FlatButton
		        label="Отмена"
		        onClick={this.dialog.bind(this, false)}
		      />
				]}
        modal={false}
        open={this.state.open}
        onRequestClose={this.dialog.bind(this, false)}
      >
      	Вы уверены, что хотите выйти?
      </Dialog>
			<AppBar
		    title="AstralInsider"
		    onLeftIconButtonClick={this.menu}
		    onRightIconButtonClick={this.dialog.bind(this, true)}
		    iconElementRight = {
		    	<IconButton>
		    		<ExitToApp />
		    	</IconButton>
		    }
		  />
	  </div>
	}
}
export default connect(state => ({
	state: state.app.toJS()
}))(Header);