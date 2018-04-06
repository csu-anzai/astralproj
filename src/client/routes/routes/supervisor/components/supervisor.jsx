import React from 'react';
import { Line } from 'react-chartjs-2';
import { GridList, GridTile } from 'material-ui/GridList';
export default class Supervisor extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			ip: this.props.state.statistic && this.props.state.statistic.ip || [],
			ooo: this.props.state.statistic && this.props.state.statistic.ooo || [],
			labels: this.props.state.statistic && this.props.state.statistic.labels || []
		}
	}
	render(){
		return <div>
			<div style = {{
				maxWidth: "800px",
				margin: "0 auto"
			}}>
				<h2 style = {{textAlign: "center", fontFamily: "Roboto"}}>Количество компаний за период</h2>
				<Line data = {{
					labels: this.state.labels,
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
				      data: this.state.ooo
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
				      data: this.state.ip
				    }
				  ]
				}}/>
			</div>
		</div>
	}
}