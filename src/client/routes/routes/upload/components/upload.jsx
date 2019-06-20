import React from 'react';
import Paper from 'material-ui/Paper';
import RaisedButton from 'material-ui/RaisedButton';
import CircularProgress from 'material-ui/CircularProgress';
import axios from 'axios';
import { ws } from '../../../../../env.json';

export default class Download extends React.Component {
	constructor(props) {
		super(props);
		this.state = {
			fileName: null,
			loading: false,
			stats: false,
			error: false,
		}
	}

	handleChange(e) {
	 	const formData = new FormData();

	 	const file = e.currentTarget.files[0];
		formData.append('file', file);

		this.setState({
			loading: true,
			stats: false,
			error: false,
			fileName: file.name
		});

	  axios.post(`${ws.location}:${ws.port}/api/uploadCompanies`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
    }).then((response) => {
	  	this.setState({
	  		stats: response.data,
	  		loading: false,
	  		error: false
	  	});
	  }).catch(err => {
	  	this.setState({
	  		loading: false,
	  		error: true
	  	});
	  });

	}

	handleFile() {
		this.refs.file.click();
	}

	render(){
		const { state } = this;
		const { stats, error, loading, fileName } = state;
		return (
			<div>
				<Paper style={{
					margin: '5em',
					maxWidth: '450px',
					padding: '3em'
				}} zDepth={1}>
					<input style={{display: 'none'}} ref="file" type="file" onChange={this.handleChange.bind(this)} />
					<h1>Загрузка старой базы лидов</h1>
					<p>Все телефоны и e-mail загрузятся в отдельные поля</p>
	        { loading ? <div>
	        	<p>Обработка: <b>{fileName}</b></p>
	        	<CircularProgress />
	        </div> : (
	        	<RaisedButton
		        	label = "Загрузить xls"
		        	backgroundColor="#2196f3"
		        	labelColor = "#fff"
		        	key = {1}
		        	onClick = {this.handleFile.bind(this)}
		        />
	        )}
	        {stats && <div>
	        	<ul>
	        		<li>Всего обработано: <b>{stats.counter}</b></li>
	        		<li>Новых Лидов: <b>{stats.new}</b></li>
	        		<li>Дублий: <b>{stats.dubble}</b></li>
	        		<li>Время выполнения: <b>{(stats.timeLoad / 1000).toFixed(3) } секунд</b></li>
	        	</ul>
	        </div>}
	        {error && <p><b style={{color: "red"}}>Ошибка сервера</b></p>}
				</Paper>
			</div>
		)
	}
}