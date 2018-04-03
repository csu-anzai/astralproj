import React from 'react';
import Paper from 'material-ui/Paper';
import TextField from 'material-ui/TextField';
import FlatButton from 'material-ui/FlatButton';
import { fromJS } from 'immutable';
import { push } from 'react-router-redux';
const paperStyle = {
	position: "absolute",
	top: "0",
	right: "0",
	bottom: "0",
	left: "0",
	margin: "auto",
	width: "500px",
	height: "269px",
	padding: "20px 15px",
};
const hStyle = {
	textAlign: "center",
	fontWeight: "normal",
	fontSize: "30px",
	color: "#039BE5",
	margin: "0"
};
const authButtonStyle = {
	position: "absolute",
	bottom: "40px",
	right: "0",
	margin: "auto"
};
export default class ForgotPassword extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			email: ""
		}
	}
	Input(name, event, value){
		this.setState({
			[name]: value
		});
	}
	send(){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "sendPasswordToEmail",
				values: [
					this.props.state.connectionHash,
					this.state.email
				]
			}
		});
		this.props.dispatch(push("/login"));
	}
	render(){
		return <Paper style={paperStyle} zDepth={2}>
			<h2 style={ hStyle }>Востановление пароля</h2>
			<TextField 
				floatingLabelText = "Email"
				fullWidth = { true }
				onChange = { this.Input.bind(this, "email") }
				errorText = { !/..*@..*\...*/.test(this.state.email) && "email должен быть вида: some@mail.ru" }
				style = {{
					marginTop: "28px"
				}}
			/>
			<FlatButton 
				label = "Отправить"
				primary = { true }
				style = { authButtonStyle }
				onClick = { this.send.bind(this) }
				disabled = { 
					/..*@..*\...*/.test(this.state.email) ? 
						false :
						true
				}
			/>
		</Paper>
	}
}