import React from 'react';
import { Line, Doughnut } from 'react-chartjs-2';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import Divider from 'material-ui/Divider';
const partStyle = {
	maxWidth: "800px",
	margin: "0 auto"
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
			colors: [
				["rgb(75,192,192)", "rgba(75,192,192,0.4)"],
				["rgb(173,162,249)", "rgba(173,162,249,0.4)"],
				["rgb(160,226,150)", "rgba(160,226,150,0.4)"]
			]
		}
		this.changeTypeToView = this.changeTypeToView.bind(this);
		this.changePeriod = this.changePeriod.bind(this);
		this.changeUser = this.changeUser.bind(this);
	}
	changeTypeToView(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
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
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						user: payload
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
					Количество необработанных компаний в базе
				</h2>
				<Doughnut options = {{}} data = {{
					datasets: [
						{
							backgroundColor: ["#90CAF9", "#81C784", "#FFD54F"],
			        data: this.props.state.statistic && this.props.state.statistic.templates.map(template => template.freeItems) || []
			    	}
			    ],
			    labels: this.props.state.statistic && this.props.state.statistic.templates.map(template => template.name) || []
				}}/>
			</div>
		</div>
	}
}