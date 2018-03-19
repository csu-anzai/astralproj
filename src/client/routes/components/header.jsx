import React from 'react';
import AppBar from 'material-ui/AppBar';
import { connect } from 'react-redux';
class Header extends React.Component {
	render(){
		return <AppBar
	    title="AstralInsider"
	    onLeftIconButtonClick={this.props.dispatch.bind(this, {
	    	type: "changeMenuState"
	    })}
	  />
	}
}
export default connect(state => ({
	state: state.app.toJS()
}))(Header);