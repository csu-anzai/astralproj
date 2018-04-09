import React from 'react';
import { Line, Doughnut } from 'react-chartjs-2';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
export default class Supervisor extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			typesNames: ["Все", "Ошибка при обработке", "Обработка в процессе", "Успешная обработка", "Интересные", "Не интересные"],
			typeToView: this.props.state.statistic && this.props.state.statistic.typeToView || 0,
			period: this.props.state.statistic && this.props.state.statistic.period || 3,
			colors: [
				["rgb(75,192,192)", "rgba(75,192,192,0.4)"],
				["rgb(173,162,249)", "rgba(173,162,249,0.4)"],
				["rgb(160,226,150)", "rgba(160,226,150,0.4)"]
			]
		}
		this.changeTypeToView = this.changeTypeToView.bind(this);
		this.changePeriod = this.changePeriod.bind(this);
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
						typeToView: key
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
						period: key
					})
				]
			}
		})
	}
	render(){
		return <div>
			<div style = {{
				maxWidth: "800px",
				margin: "0 auto"
			}}>
				<h2 style = {{textAlign: "center", fontFamily: "Roboto"}}>Количество компаний за период</h2>
				<SelectField
          floatingLabelText="Тип компаний"
          value={this.props.state.statistic && this.props.state.statistic.typeToView != undefined ? this.props.state.statistic.typeToView : this.state.typeToView}
          onChange={this.changeTypeToView}
        >
        	{
        		this.state.typesNames.map((type, key) => (
        			<MenuItem value = {key} key = {key} primaryText = {type} />
        		))
        	}
        </SelectField>
        <SelectField
          floatingLabelText="Период"
          value={this.props.state.statistic && this.props.state.statistic.period != undefined ? this.props.state.statistic.period : this.state.period}
          onChange={this.changePeriod}
        >
        	<MenuItem value = {0} primaryText = "Неделя" />
        	<MenuItem value = {1} primaryText = "Месяц" />
        	<MenuItem value = {2} primaryText = "Год" />
        	<MenuItem value = {3} primaryText = "Все время" />
        </SelectField>
				<Line xAxisID = "Дата" yAxisID = "Количество компаний" data = {{
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
		</div>
	}
}