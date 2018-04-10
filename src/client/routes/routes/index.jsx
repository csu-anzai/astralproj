import Tinkoff from './tinkoff';
import Supervisor from './supervisor';
import Login from './login';
import ForgotPassword from './forgotPassword';
import React from 'react';
import { Route, Switch, Redirect } from 'react-router';
import { connect } from 'react-redux';
class Childrens extends React.Component {
	render(){
		return <Switch>
			{
				this.props.state.auth && (
					this.props.state.userType == 1 ? [
						<Route key = {1} path = "/supervisor" component = {Supervisor}/>,
						<Route key = {2} path = "/tinkoff" component = {Tinkoff}/>
					] :
					this.props.state.userType == 18 ?
						<Route path = "/tinkoff" component = {Tinkoff}/> :
						<Route path = "/supervisor" component = {Supervisor}/>
				)
			}
			{
				!this.props.state.auth && <Route path = "/login" component = {Login} />
			}
			<Route path = "/forgotPassword" component = {ForgotPassword} />
			<Redirect to = {
				!this.props.state.auth ? 
					"/login" : 
					(this.props.state.userType == 1 || this.props.state.userType == 18) ? 
						"/tinkoff" : 
						"/supervisor" 
			}/>
		</Switch>
	}
}
export default connect(state => ({
	state: state.app.toJS()
}))(Childrens);