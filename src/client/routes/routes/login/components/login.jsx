import React from 'react';
import Paper from 'material-ui/Paper';
import TextField from 'material-ui/TextField';
import FlatButton from 'material-ui/FlatButton';
import CircularProgress from 'material-ui/CircularProgress';
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
	height: "312px",
	padding: "20px 15px",
};
const hStyle = {
	textAlign: "center",
	fontWeight: "normal",
	fontSize: "38px",
	color: "#039BE5",
	margin: "0"
};
const authButtonStyle = {
	position: "absolute",
	bottom: "40px",
	right: "0",
	margin: "auto",
};
const forgotPasswordStyle = {
	color: "#4FC3F7",
	borderBottom: "1px solid #4FC3F7",
	paddingBottom: "1px",
	cursor: "pointer",
	fontSize: "12px"
};
const forgotPasswordContainerStyle = {
	position: "absolute",
	bottom: "10px",
	margin: "auto",
	width: "100%",
	textAlign: "center"
};
const progressStyle = {
	position: "absolute",
	right: "0",
	left: "0",
	top: "0",
	bottom: "0",
	margin: "auto",
	width: "80px",
	height: "80px"
};
const progressMessageStyle = {
	position: "absolute",
	textAlign:"center",
	top: "0",
	right: "0",
	left: "0",
	bottom: "0",
	margin: "auto",
	height: "1em",
	lineHeight: "130px"
};
const messageStyle = {
  textAlign: "center",
  fontSize: "14px",
  color: "#f38d85"
}
export default class Login extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			email: "",
			password: "",
			progress: props.state.progress || false,
			message: props.state.loginMessage || "Выполняется авторизация"
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
				query: "auth",
				values: [
					this.props.state.connectionHash,
					this.state.email,
					this.state.password
				]
			}
		});
	}
	render(){
		if(localStorage.hasOwnProperty("app") && !this.props.state.auth && !this.props.state.try){
			let app = JSON.parse(localStorage.getItem("app"));
			if (app.hasOwnProperty("userHash") && app.hasOwnProperty("connectionHash")) {
				this.props.dispatch({
					type: "query",
					socket: true,
					data: {
						query: "autoAuth",
						values: [
							app.userHash,
							this.props.state.connectionHash
						]
					}
				});
			}
		}
		return this.state.progress ?
			<div>
				<div style = { progressStyle }> 
					<CircularProgress size={80} thickness={5}/>
				</div>
				<div style = {progressMessageStyle}>{this.props.state.loginMessage || this.state.message}</div>
			</div> : 
			<Paper style={paperStyle} zDepth={2}>
			<h2 style={ hStyle }>Вход</h2>
			<div style={ messageStyle }>{this.props.state.loginMessage}</div>
			<TextField 
				floatingLabelText = "Email"
				fullWidth = { true }
				onChange = { this.Input.bind(this, "email") }
				errorText = { !/..*@..*\...*/.test(this.state.email) && "email должен быть вида: some@mail.ru" }
			/>
			<TextField 
				floatingLabelText = "Пароль"
				fullWidth = { true }
				type = "password"
				onChange = { this.Input.bind(this, "password") }
				errorText = { !this.state.password && "Поле не может быть пустым" }
			/>
			<FlatButton 
				label = "Авторизоваться"
				primary = { true }
				style = { authButtonStyle }
				onClick = { this.send.bind(this) }
				disabled = { 
					/..*@..*\...*/.test(this.state.email) ? 
						this.state.password ?
							false :
							true :
						true
				}
			/>
			<div style = { forgotPasswordContainerStyle }>
				<span style = { forgotPasswordStyle } onClick = {(() => {
					this.props.dispatch(push("/forgotPassword"))
				}).bind(this)}>
					Востановление пароля
				</span>
			</div>
		</Paper>
	}
}