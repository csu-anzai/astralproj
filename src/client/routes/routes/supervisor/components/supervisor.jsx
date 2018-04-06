import React from 'react';
import { Line } from 'react-chartjs-2';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
export default class Supervisor extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			types: ["allTypes", "apiError", "apiProcess", "apiSuccess", "validate", "invalidate"],
			typesNames: ["Все", "Ошибка при обработке", "Обработка в процессе", "Успешная обработка", "Интересные", "Не интересные"],
			typeToView: 0
		}
		this.changeTypeToView = this.changeTypeToView.bind(this);
	}
	changeTypeToView(event, key, payload) {
		this.setState({
			typeToView: key
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
          value={this.state.typeToView}
          onChange={this.changeTypeToView}
          style = {{
          	margin: "0 auto"
          }}
        >
        	{
        		this.state.typesNames.map((type, key) => (
        			<MenuItem value = {key} key = {key} primaryText = {type} />
        		))
        	}
        </SelectField>
				<Line xAxisID = "Дата" yAxisID = "Количество компаний" data = {{
					labels: this.props.state.statistic && this.props.state.statistic[this.state.types[this.state.typeToView]].labels || [],
				  datasets: [
				    {
				      label: "ООО",
				      fill: false,
				      lineTension: 0.1,
				      backgroundColor: 'rgba(75,192,192,0.4)',
				      borderColor: 'rgba(75,192,192,1)',
				      borderCapStyle: 'butt',
				      borderDash: [],
				      borderDashOffset: 0.0,
				      borderJoinStyle: 'miter',
				      pointBorderColor: 'rgba(75,192,192,1)',
				      pointBackgroundColor: '#fff',
				      pointBorderWidth: 1,
				      pointHoverRadius: 10,
				      pointHoverBackgroundColor: 'rgba(75,192,192,1)',
				      pointHoverBorderColor: 'rgba(220,220,220,1)',
				      pointHoverBorderWidth: 2,
				      pointRadius: 5,
				      pointHitRadius: 10,
				      data: this.props.state.statistic && this.props.state.statistic[this.state.types[this.state.typeToView]].ooo || []
				    },
				    {
				      label: "ИП",
				      fill: false,
				      lineTension: 0.1,
				      backgroundColor: 'rgba(173,162,249,0.4)',
				      borderColor: 'rgb(173,162,249)',
				      borderCapStyle: 'butt',
				      borderDash: [],
				      borderDashOffset: 0.0,
				      borderJoinStyle: 'miter',
				      pointBorderColor: 'rgb(173,162,249)',
				      pointBackgroundColor: '#fff',
				      pointBorderWidth: 1,
				      pointHoverRadius: 10,
				      pointHoverBackgroundColor: 'rgb(173,162,249)',
				      pointHoverBorderColor: 'rgba(220,220,220,1)',
				      pointHoverBorderWidth: 2,
				      pointRadius: 5,
				      pointHitRadius: 10,
				      data: this.props.state.statistic && this.props.state.statistic[this.state.types[this.state.typeToView]].ip || []
				    },
				    {
				      label: "ВСЕ",
				      fill: false,
				      lineTension: 0.1,
				      backgroundColor: 'rgba(160,226,150,0.4)',
				      borderColor: 'rgb(160,226,150)',
				      borderCapStyle: 'butt',
				      borderDash: [],
				      borderDashOffset: 0.0,
				      borderJoinStyle: 'miter',
				      pointBorderColor: 'rgb(160,226,150)',
				      pointBackgroundColor: '#fff',
				      pointBorderWidth: 1,
				      pointHoverRadius: 10,
				      pointHoverBackgroundColor: 'rgb(160,226,150)',
				      pointHoverBorderColor: 'rgba(220,220,220,1)',
				      pointHoverBorderWidth: 2,
				      pointRadius: 5,
				      pointHitRadius: 10,
				      data: this.props.state.statistic && this.props.state.statistic[this.state.types[this.state.typeToView]].all || []
				    }
				  ]
				}}/>
			</div>
		</div>
	}
}