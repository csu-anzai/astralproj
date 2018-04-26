import React from 'react';
import { Line, Doughnut, Bar } from 'react-chartjs-2';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import Divider from 'material-ui/Divider';
import Checkbox from 'material-ui/Checkbox';
const partStyle = {
	maxWidth: "800px",
	margin: "0 auto 10px"
};
const headerStyle = {
	textAlign: "center", 
	fontFamily: "Roboto, sans-serif", 
	fontWeight: "normal"
};
export default class Supervisor extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			typeToView: this.props.state.statistic && this.props.state.statistic.typeToView || 0,
			period: this.props.state.statistic && this.props.state.statistic.period || 3,
			user: this.props.state.statistic && this.props.state.statistic.user || 0,
			dataPeriod: this.props.state.statistic && this.props.state.statistic.dataPeriod || 0,
			dataFree: this.props.state.statistic && (this.props.state.statistic.dataFree ? true : false) || false,
			dataBank: this.props.state.statistic && (this.props.state.statistic.dataBank ? true : false) || false,
			colors: [
				["rgb(75,192,192)", "rgba(75,192,192,0.4)"],
				["rgb(173,162,249)", "rgba(173,162,249,0.4)"],
				["rgb(160,226,150)", "rgba(160,226,150,0.4)"]
			]
		}
		this.changeTypeToView = this.changeTypeToView.bind(this);
		this.changePeriod = this.changePeriod.bind(this);
		this.changeUser = this.changeUser.bind(this);
		this.changeDataPeriod = this.changeDataPeriod.bind(this);
		this.changeBank = this.changeBank.bind(this);
		this.changeDataFree = this.changeDataFree.bind(this);
	}
	changeTypeToView(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						typeToView: payload
					})
				]
			}
		})
	}
	changePeriod(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						period: payload
					})
				]
			}
		})
	}
	changeUser(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						user: payload
					})
				]
			}
		})
	}
	changeDataPeriod(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						dataPeriod: payload
					})
				]
			}
		})
	}
	changeDataFree(obj, data){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						dataFree: data ? 1 : 0
					})
				]
			}
		})
	}
	changeBank(obj, data){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						dataBank: data ? 1 : 0
					})
				]
			}
		})
	}
	render(){
		return <div>
			<div style = {partStyle}>
				<h2 style = {headerStyle}>Количество обработанных компаний за период</h2>
				<SelectField
          floatingLabelText="Тип компаний"
          value={this.props.state.statistic && this.props.state.statistic.typeToView != undefined ? this.props.state.statistic.typeToView : this.state.typeToView}
          onChange={this.changeTypeToView}
        >
        	<MenuItem value = {0} primaryText = "Все" />
        	<Divider/>
        	<MenuItem value = {7} primaryText = "Утвержденные все" />
        	<MenuItem value = {1} primaryText = "Утвержденные с ошибкой" />
        	<MenuItem value = {2} primaryText = "Утвержденные в обработке" />
        	<MenuItem value = {3} primaryText = "Утвержденные успешные" />
        	<Divider/>
        	<MenuItem value = {9} primaryText = "Обработанные все" />
        	<MenuItem value = {4} primaryText = "Обработанные интересные" />
        	<MenuItem value = {5} primaryText = "Обработанные не интересные" />
        	<MenuItem value = {8} primaryText = "Обработанные не утвержденные" />
        	<MenuItem value = {10} primaryText = "Обработанные перезвон" />
        	<Divider/>
        	<MenuItem value = {6} primaryText = "Необработанные в работе" />
        </SelectField>
        <SelectField
          floatingLabelText="Период"
          value={this.props.state.statistic && this.props.state.statistic.period != undefined ? this.props.state.statistic.period : this.state.period}
          onChange={this.changePeriod}
        >
        	<MenuItem value = {3} primaryText = "Все время" />
        	<MenuItem value = {2} primaryText = "Год" />
        	<MenuItem value = {1} primaryText = "Месяц" />
        	<MenuItem value = {0} primaryText = "Неделя" />
        	<MenuItem value = {5} primaryText = "Вчера" />
        	<MenuItem value = {4} primaryText = "Сегодня" />
        </SelectField>
        <SelectField
          floatingLabelText="Сотрудники"
          value={this.props.state.statistic && this.props.state.statistic.user != undefined ? this.props.state.statistic.user : this.state.user}
          onChange={this.changeUser}
        >
        	<MenuItem value = {0} primaryText = "Все сотрудники"/>
        	{
        		this.props.state.statistic && this.props.state.statistic.users.map((user, key) => (
        			<MenuItem value = {user.userID} key = {key} primaryText = {user.userName}/>
        		))
        	}
        </SelectField>
        <div style = {{
        	margin: "10px 0",
        	textAlign: "center",
        	fontFamily: "Roboto, sans-serif"
        }}>
        	{
        		this.props.state.statistic && this.props.state.statistic.templates.map(template => template.items.length > 0 ? template.items.reduce((before, after) => before + after) : 0).reduce((before, after) => before + after)
        	}
        	{" компаний за период: "}
        	{
        		this.props.state.statistic && 
        		(this.props.state.statistic.dateStart == this.props.state.statistic.dateEnd ? 
        			this.props.state.statistic.dateStart :
        			`${this.props.state.statistic.dateStart} – ${this.props.state.statistic.dateEnd}`)
        	}
        </div>
				<Line data = {{
					labels: this.props.state.statistic && this.props.state.statistic.labels || [],
				  datasets: this.props.state.statistic && this.props.state.statistic.templates.map((template, key) => ({
				  	label: template.name || "Компании",
			      fill: false,
			      lineTension: 0.1,
			      backgroundColor: this.state.colors[key][1],
			      borderColor: this.state.colors[key][0],
			      borderCapStyle: 'butt',
			      borderDash: [],
			      borderDashOffset: 0.0,
			      borderJoinStyle: 'miter',
			      pointBorderColor: this.state.colors[key][0],
			      pointBackgroundColor: '#fff',
			      pointBorderWidth: 1,
			      pointHoverRadius: 10,
			      pointHoverBackgroundColor: this.state.colors[key][0],
			      pointHoverBorderColor: 'rgba(220,220,220,1)',
			      pointHoverBorderWidth: 2,
			      pointRadius: 5,
			      pointHitRadius: 10,
			      data: template.items || []
				  }))
				}}/>
			</div>
			<div style = {partStyle}>
				<h2 style = {headerStyle}>
					Количество компаний в базе
				</h2>
				<SelectField
          floatingLabelText="Период"
          value={this.props.state.statistic && this.props.state.statistic.dataPeriod != undefined ? this.props.state.statistic.dataPeriod : this.state.dataPeriod}
          onChange={this.changeDataPeriod}
        >
        	<MenuItem value = {3} primaryText = "Все время" />
        	<MenuItem value = {2} primaryText = "Год" />
        	<MenuItem value = {1} primaryText = "Месяц" />
        	<MenuItem value = {0} primaryText = "Неделя" />
        	<MenuItem value = {4} primaryText = "Вчера" />
        	<MenuItem value = {5} primaryText = "Сегодня" />
        </SelectField>
        <Checkbox 
        	label = "Подходящие для Банка"
        	checked = {this.props.state.statistic && this.props.state.statistic.dataBank != undefined ? (this.props.state.statistic.dataBank ? true : false) : this.state.dataBank}
        	onCheck = {this.changeBank}
        	style = {{
        		display: "inline-block",
        		width: "auto",
        		verticalAlign: "super",
        		whiteSpace: "nowrap",
        		marginLeft: "10px"
        	}}
        />
        <Checkbox 
        	label = "Только свободные"
        	checked = {this.props.state.statistic && this.props.state.statistic.dataFree != undefined ? (this.props.state.statistic.dataFree ? true : false) : this.state.dataFree}
        	onCheck = {this.changeDataFree}
        	style = {{
        		display: "inline-block",
        		width: "auto",
        		verticalAlign: "super",
        		whiteSpace: "nowrap",
        		marginLeft: "10px"
        	}}
        />
        <div style = {{
        	margin: "10px 0",
        	textAlign: "center",
        	fontFamily: "Roboto, sans-serif"
        }}>
        	{
        		this.props.state.statistic && this.props.state.statistic.templates.map(template => template.infoItems.length > 0 ? template.infoItems.reduce((before, after) => before + after) : 0).reduce((before, after) => before + after)
        	}
        	{" компаний за период: "}
        	{
        		this.props.state.statistic && 
        		(this.props.state.statistic.dataDateStart == this.props.state.statistic.dataDateEnd ? 
        			this.props.state.statistic.dataDateStart :
        			`${this.props.state.statistic.dataDateStart} – ${this.props.state.statistic.dataDateEnd}`)
        	}
        </div>
				<Bar data = {{
			    labels: this.props.state.statistic && this.props.state.statistic.dataLabels || [],
					datasets: this.props.state.statistic && this.props.state.statistic.templates.map((template, key) => ({
						label: template.name,
						backgroundColor: this.state.colors[key][1],
						borderColor: this.state.colors[key][0],
						pointHoverBackgroundColor: this.state.colors[key][0],
						pointHoverBorderColor: 'rgba(220,220,220,1)',
						data: template.infoItems || []
					}))
				}}/>
			</div>
		</div>
	}
}