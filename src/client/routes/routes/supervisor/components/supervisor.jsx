import React from 'react';
import { Line, Doughnut, Bar } from 'react-chartjs-2';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import Divider from 'material-ui/Divider';
import Checkbox from 'material-ui/Checkbox';
import DatePicker from 'material-ui/DatePicker';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';
import FlatButton from 'material-ui/FlatButton';
import Work from 'material-ui/svg-icons/action/work';
import Cloud from 'material-ui/svg-icons/file/cloud';
import Refresh from 'material-ui/svg-icons/navigation/refresh';
import IconButton from 'material-ui/IconButton';
import ArrowBack from 'material-ui/svg-icons/navigation/arrow-back';
import ArrowForward from 'material-ui/svg-icons/navigation/arrow-forward';
import {
  Table,
  TableBody,
  TableFooter,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn,
} from 'material-ui/Table';
const partStyle = {
	maxWidth: "800px",
	margin: "0 auto 10px",
	overflowX: "auto"
};
const headerStyle = {
	textAlign: "center", 
	fontFamily: "Roboto, sans-serif", 
	fontWeight: "normal"
};
const datePickerStyle = {
  display: "inline-block",
  width: "99px",
  overflowX: "hidden",
  margin: "-18px 10px"
};
const typeNames = [
	{
		type_id: 13,
		type_name: "Утверждено"
	},
	{
		type_id: 14,
		type_name: "Не интересно"
	},
	{
		type_id: 36,
		type_name: "Нет связи"
	},
	{
		type_id: 23,
		type_name: "Перезвонить"
	},
	{
		type_id: 37,
		type_name: "Сложные"
	},
	{
		type_id: 35,
		type_name: "Рабочий список: первичный недозвон"
	},
	{
		type_id: 9,
		type_name: "Рабочий список: в работе"
	}
];
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
			],
			selectedIndex: 0
		}
		this.changeType = this.changeType.bind(this);
		this.changePeriod = this.changePeriod.bind(this);
		this.changeUser = this.changeUser.bind(this);
		this.changeDataPeriod = this.changeDataPeriod.bind(this);
		this.changeBank = this.changeBank.bind(this);
		this.changeDataFree = this.changeDataFree.bind(this);
		this.changeDate = this.changeDate.bind(this);
		this.getFormated = this.getFormated.bind(this);
		this.refresh = this.refresh.bind(this);
		this.resetStatisticArr = this.resetStatisticArr.bind(this);
		this.createFile = this.createFile.bind(this);
		this.changeStatus = this.changeStatus.bind(this);
		this.changeDataBanks = this.changeDataBanks.bind(this);
	}
	createFile(){
		this.props.dispatch({
			type: "procedure",
			socket: true,
			data: {
				query: "createStatisticFile",
				values: [
					this.props.state.connectionHash
				]
			}
		})
	}
	changeType(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						types: payload,
						workingCompaniesOffset: 0
					})
				]
			}
		});
		this.resetStatisticArr("working");
		this.resetStatisticArr("workingCompanies");
	}
	resetStatisticArr(type){
		this.props.dispatch({
			type: "merge",
			data: {
				statistic: Object.assign(this.props.state.statistic, {
					[type]: []
				})
			}
		});
		if(type == "workingCompanies" || type == "working") {
			this.props.dispatch({
				type: "merge",
				data: {
					statistic: Object.assign(this.props.state.statistic, {
						message: "",
						fileURL: ""
					})
				}
			});
		}
	}
	changePeriod(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						period: payload,
						workingCompaniesOffset: 0
					})
				]
			}
		});
		this.resetStatisticArr("working");
		this.resetStatisticArr("workingCompanies");
	}
	changeUser(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						selectedUsers: payload,
						workingCompaniesOffset: 0
					})
				]
			}
		});
		this.resetStatisticArr("working");
		this.resetStatisticArr("workingCompanies");
	}
	changeDataPeriod(event, key, payload) {
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						dataPeriod: payload
					})
				]
			}
		});
		this.resetStatisticArr("data");
	}
	changeDataFree(obj, data){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						dataFree: data ? 1 : 0
					})
				]
			}
		});
		this.resetStatisticArr("data");
	}
	changeBank(event, key, payload){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						banks: payload.map(i => ({
							bank_id: i
						}))
					})
				]
			}
		});
		this.resetStatisticArr("working");
		this.resetStatisticArr("workingCompanies");
	}
	changeStatus(event, key, payload){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						bankStatuses: payload
					})
				]
			}
		});
		this.resetStatisticArr("working");
		this.resetStatisticArr("workingCompanies");
	}
	changeDate(date, dateStartBool){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						period: 6,
						[dateStartBool ? "dateStart" : "dateEnd"]: `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`,
						workingCompaniesOffset: 0
					})
				]
			}
		});
		this.resetStatisticArr("working");
		this.resetStatisticArr("workingCompanies");
	}
	changeDataDate(date, dateStartBool){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						dataPeriod: 6,
						[dateStartBool ? "dataDateStart" : "dataDateEnd"]: `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`
					})
				]
			}
		});
		this.resetStatisticArr("data");
	}
	changeDataBanks(event, key, payload){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticfilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						dataBanks: payload
					})
				]
			}
		})
		this.resetStatisticArr("data");
	}
	getFormated(type, template){
		let arr = this.props.state.statistic[type].filter(item => item.template_name == template) || [],
				datesArr = this.props.state.statistic[type].filter((item, key, self) => self.findIndex(i => i.date == item.date) == key).map(i => i.date) || [],
				time = type == "data" ? "time" : "hour",
				timesArr = datesArr.length == 1 ? this.props.state.statistic[type].filter((item, key, self) => self.findIndex(i => i[time] == item[time]) == key).map(i => i[time]) : [],
	 			newArr = datesArr.length > 1 ? 
	 				datesArr.map(item => arr.filter(i => i.date == item)).map(item => item.length > 0 ? 
 						item.reduce((before, after) => ({companies: before.companies + after.companies})).companies : 
 						0) : 
	 				datesArr.length == 1 ? 
	 					timesArr.map(item => arr.filter(i => i[time] == item)).map(item => item.length > 0 ? 
	 						item.reduce((before, after) => ({companies: before.companies + after.companies})).companies : 
	 						0) : 
	 					[];
		return newArr;
	}
	select(num){
		this.setState({
			selectedIndex: num
		});
	}
	refresh(){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "getUserStatistic",
				values: [
					this.props.state.connectionHash,
					this.state.selectedIndex == 0 ? "working" : "data"
				]
			}
		});
		this.resetStatisticArr(this.state.selectedIndex == 0 ? "working" : "data");
		this.state.selectedIndex == 0 && this.resetStatisticArr("workingCompanies");
	}
	componentDidMount(){
		let component = document.querySelector("#app > div > div:nth-child(2) > div:nth-child(4) > div > div");
		component && (component.style.overflow = "auto");
	}
	workingPaging(limit, offset){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						workingCompaniesOffset: offset,
						workingCompaniesLimit: limit
					})
				]
			}
		});
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "getUserStatistic",
				priority: true,
				values: [
					this.props.state.connectionHash,
					"working"
				]
			}
		});
		this.resetStatisticArr("workingCompanies");
	}
	render(){
		return <div>
			<BottomNavigation selectedIndex={this.state.selectedIndex}>
				<BottomNavigationItem 
					label="ОБРАБОТКА ЛИДОВ"
          icon={<Work/>}
          onClick={this.select.bind(this, 0)}
				/>
				<BottomNavigationItem 
					label="ЗАЛИВКИ В БАЗУ"
          icon={<Cloud/>}
          onClick={this.select.bind(this, 1)}
				/>
			</BottomNavigation>
			<div style = {{
				textAlign: "center",
				margin: "10px 0 0"
			}}>
				<Refresh 
					style = {{
						cursor: "pointer"
					}}
					onClick = {this.refresh}
				/>
			</div>
			{
				this.state.selectedIndex == 0 ?
					[
					<div key = {1} style = {partStyle}>
					<SelectField
	          floatingLabelText="Тип компаний"
	          value={this.props.state.statistic && this.props.state.statistic.types}
	          onChange={this.changeType}
	          autoWidth = {true}
	          multiple = {true}
	          floatingLabelFixed = {true}
	          selectionRenderer = {values => values.length == 0 ? "Все типы" : values.length == 1 ? typeNames.find(i => i.type_id == values[0]).type_name : `Выбрано типов: ${values.length}`}
	        >
	        	<MenuItem value = {13} primaryText = "Утверждено" />
	        	{
	        		this.props.state.statistic && this.props.state.statistic.types.indexOf(13) > -1 && 
		        	<SelectField
		        		style = {{
		        			margin: "0 24px"
		        		}}
		        		floatingLabelText = "Для банков"
		        		multiple = {true}
		        		autoWidth = {true}
		        		onChange={this.changeBank}
		        		floatingLabelFixed = {true}
		        		value = {this.props.state.statistic && this.props.state.statistic.banks && this.props.state.statistic.banks.map(bank => bank.bank_id)}
		        		selectionRenderer = {values => values.length == 0 ? "Все банки и все статусы" : values.length == 1 ? this.props.state.banks.find(i => i.id == values[0]).name : `Выбрано банков: ${values.length}`}
		        	>
		        		{this.props.state.banks && this.props.state.banks.map((bank, key) => (
		        			<MenuItem value = {bank.id} primaryText = {bank.name} key = {key}/>
		        		))}
		        	</SelectField>
	        	}
	        	{this.props.state.statistic && this.props.state.statistic.banks && this.props.state.statistic.banks.map((bank, key) => [
        			<br />,
        			<SelectField
        				floatingLabelText = {`Статусы банка: ${bank.bank_name}`}
        				style = {{
		        			margin: "0 24px"
		        		}}
        				multiple = {true}
        				autoWidth = {true}
        				onChange = {this.changeStatus}
        				value = {this.props.state.statistic && this.props.state.statistic.bankStatuses}
        				key = {key}
        				floatingLabelFixed = {true}
        				selectionRenderer = {values => values.length == 0 ? (this.props.state.statistic.bankStatuses && this.props.state.statistic.bankStatuses.length > 0 ? "Только выбранные" : "Все статусы") : values.length == 1 ? this.props.state.statistic.banks.find(i => i.bank_statuses.map(status => status.bank_status_id).indexOf(values[0]) > -1).bank_statuses.find(status => status.bank_status_id == values[0]).bank_status_text : `Выбрано статусов: ${values.length}`}
        			>
        				{this.props.state.statistic && this.props.state.statistic.banks && this.props.state.statistic.banks.find(statisticBank => statisticBank.bank_id == bank.bank_id).bank_statuses.map((status, key) => (
        					<MenuItem key = {key} value = {status.bank_status_id} primaryText = {status.bank_status_text} />
        				))}
        			</SelectField>
        		])}
	        	<Divider/>
	        	<MenuItem value = {14} primaryText = "Не интересно" />
	        	<MenuItem value = {36} primaryText = "Нет связи" />
	        	<MenuItem value = {23} primaryText = "Перезвонить" />
	        	<MenuItem value = {37} primaryText = "Сложные" />
	        	<Divider/>
	        	<MenuItem value = {35} primaryText = "Рабочий список: первичный недозвон" />
	        	<MenuItem value = {9} primaryText = "Рабочий список: в работе" />
	        </SelectField>
	        <SelectField
	          floatingLabelText="Период"
	          value={this.props.state.statistic && this.props.state.statistic.period != undefined ? +this.props.state.statistic.period : +this.state.period}
	          onChange={this.changePeriod}
	          autoWidth = {true}
	        >
	        	<MenuItem value = {3} primaryText = "Все время" />
	        	<MenuItem value = {2} primaryText = "Год" />
	        	<MenuItem value = {1} primaryText = "Месяц" />
	        	<MenuItem value = {0} primaryText = "Неделя" />
	        	<MenuItem value = {5} primaryText = "Вчера" />
	        	<MenuItem value = {4} primaryText = "Сегодня" />
	        	<MenuItem value = {6} primaryText = "Собственный" />
	        </SelectField>
	        <SelectField
	          floatingLabelText="Сотрудники"
	          floatingLabelFixed = {true}
	          value={this.props.state.statistic && this.props.state.statistic.selectedUsers}
	          onChange={this.changeUser}
	          autoWidth = {true}
	          multiple = {true}
	          selectionRenderer = {values => values.length == 0 ? "Все сотрудники" : values.length == 1 ? this.props.state.statistic.users.find(i => i.userID == values[0]).userName : `Выбрано сотрудников: ${values.length}`}
	        >
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
	        		this.props.state.statistic && this.props.state.statistic.working && this.props.state.statistic.working.length > 0 && this.props.state.statistic.working.map(i => i.companies).reduce((before, after) => before + after) || 0
	        	}
	        	{" компаний за период: "}
	        	{
	        		(this.props.state.statistic && this.props.state.statistic.period != 6) ?
	        		(
	        			this.props.state.statistic.working && this.props.state.statistic.working.length > 0 && (this.props.state.statistic.working.map(i => i.date).filter((item, key, self) => self.indexOf(item) == key).length == 1 ? this.props.state.statistic.working[0].date : `${this.props.state.statistic.working[0].date} – ${this.props.state.statistic.working[this.props.state.statistic.working.length - 1].date}`)
	        		) :
	        		[<DatePicker 
	  						key = {0}
	  						floatingLabelText="Начальная дата"
	  						style = {datePickerStyle}
	  						defaultDate = {
	  							this.props.state.statistic ? 
	  								new Date(this.props.state.statistic.dateStart) :
	  								new Date()
	  						}
	  						onChange = {(eny, date) => {
	  							this.changeDate(date, 1);
	  						}}
	  					/>, 
	  					" — ",
	  					<DatePicker 
	  						key = {1}
	  						floatingLabelText="Конечная дата"
	  						style = {datePickerStyle}
	  						defaultDate = {
	  							this.props.state.statistic ? 
	  								new Date(this.props.state.statistic.dateEnd) :
	  								new Date()
	  						}
	  						onChange = {(eny, date) => {
	  							this.changeDate(date, 0);
	  						}}
	  					/>,
	  					this.props.state.statistic && this.props.state.statistic.working && this.props.state.statistic.working.map(i => i.date).filter((item, key, self) => self.indexOf(item) == key).length == 1 && `(только ${this.props.state.statistic.working[0].date})` || ""]
	        	}
	        </div>
	        {
	        	this.props.state.statistic && this.props.state.statistic.working && this.props.state.statistic.working.length > 0 &&
	        	[
	        		<FlatButton 
	        			key = {0}
              	label = "Создать файл"
              	primary
              	onClick = {this.createFile}
              />,
             	this.props.state.statistic && this.props.state.statistic.fileURL && <a key = {1} href = {this.props.state.statistic.fileURL} target = "_blank">{this.props.state.statistic.fileURL}</a> || "",
							<Line 
								key = {2} 
								data = {{
									labels: this.props.state.statistic && this.props.state.statistic.working && (this.props.state.statistic.working.filter((item, key, self) => self.findIndex(i => i.date == item.date) == key).length == 1 ? this.props.state.statistic.working.map(i => i.hour+":00").filter((i,k,s) => s.indexOf(i) == k) : this.props.state.statistic.working.map(i => i.date)).filter((i,k,s) => s.indexOf(i) == k) || [],
								  datasets: this.props.state.statistic && this.props.state.statistic.working && this.props.state.statistic.working.filter((item, key, self) => self.findIndex(i => i.template_name == item.template_name) == key).map((template, key) => ({
								  	label: `${template.template_name} (${this.getFormated("working", template.template_name).reduce((before, after) => (before + after))})`,
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
							      data: this.getFormated("working", template.template_name)
								  }))
								}}
								options = {{
									scales: {
				            yAxes: [{
			                ticks: {
		                    beginAtZero:true
			                }
				            }]
					        },
					        tooltips: {
					        	intersect: false,
					        	position: "nearest"
					        }
								}}
							/>
						]
	        }
					</div>,
					<div key = {2} style = {{
						display: (this.props.state.statistic && this.props.state.statistic.workingCompanies && this.props.state.statistic.workingCompanies.length > 0) ? "block" : "none"
					}}>
						<Table
								fixedHeader={false}
			          fixedFooter={false}
			          selectable={false}
			          multiSelectable={false}
			          style = {{tableLayout: "auto"}}
							>
								<TableHeader
			            displaySelectAll={false}
			            adjustForCheckbox={false}
			            enableSelectAll={false}
			          >
			          	<TableRow>
			          		<TableHeaderColumn>
			          			Название компании
			          		</TableHeaderColumn>
			          		<TableHeaderColumn>
			          			Ф.И.О
			          		</TableHeaderColumn>
			          		<TableHeaderColumn>
			          			Телефон
			          		</TableHeaderColumn>
			          		<TableHeaderColumn>
			          			ИНН
			          		</TableHeaderColumn>
			          		<TableHeaderColumn>
			          			Дата создания
			          		</TableHeaderColumn>
			          		<TableHeaderColumn>
			          			Дата обновления
			          		</TableHeaderColumn>
			          		<TableHeaderColumn>
			          			Статус
			          		</TableHeaderColumn>
			          	</TableRow>
			          </TableHeader>
			          <TableBody
			            displayRowCheckbox={false}
			            deselectOnClickaway={false}
			            showRowHover={true}
			            stripedRows={false}
			          >
			          	{
			          		this.props.state.statistic && this.props.state.statistic.workingCompanies && this.props.state.statistic.workingCompanies.length > 0 && this.props.state.statistic.workingCompanies.map((company, key) => (
			          			<TableRow
			          				key = {key}
			          			>
			          				<TableRowColumn>
			          					{company.company_organization_name}
			          				</TableRowColumn>
			          				<TableRowColumn>
			          					{`${company.company_person_name} ${company.company_person_surname} ${company.company_person_patronymic}`}
			          				</TableRowColumn>
			          				<TableRowColumn>
			          					{company.company_phone}
			          				</TableRowColumn>
			          				<TableRowColumn>
			          					{company.company_inn}
			          				</TableRowColumn>
			          				<TableRowColumn>
			          					{company.company_date_create}
			          				</TableRowColumn>
			          				<TableRowColumn>
			          					{company.company_date_update}
			          				</TableRowColumn>
			          				<TableRowColumn>
			          					{company.translate_to}
			          				</TableRowColumn>
			          			</TableRow>
			          		))
			          	}
			          	<TableRow>
			          		<TableRowColumn colSpan = {7} style = {{
			          			textAlign: "right"
			          		}}>
			          			<IconButton 
			            			title = "сюда"
			            			disabled = {
			            				this.props.state.statistic && this.props.state.statistic.hasOwnProperty("workingCompaniesOffset") && this.props.state.statistic.workingCompaniesOffset <= 0 ? true : false
			            			}
			            			onClick = {this.workingPaging.bind(this, this.props.state.statistic && this.props.state.statistic.hasOwnProperty("workingCompaniesLimit") && this.props.state.statistic.workingCompaniesLimit, this.props.state.statistic && this.props.state.statistic.hasOwnProperty("workingCompaniesOffset") && this.props.state.statistic.workingCompaniesOffset - this.props.state.statistic.workingCompaniesLimit)}
		            			>
		            				<ArrowBack/>
			            		</IconButton>
			            		<div style = {{
			            			display: "inline-block",
			            			lineHeight: "48px",
			            			verticalAlign: "top"
			            		}}>
			            			{
			            				this.props.state.statistic && this.props.state.statistic.workingCompanies && 
			            				`c ${this.props.state.statistic.workingCompaniesOffset == 0 ? 1 : this.props.state.statistic.workingCompaniesOffset} по ${this.props.state.statistic.workingCompaniesOffset + this.props.state.statistic.workingCompanies.length}` 
			            			}
			            		</div>
			            		<IconButton 
			            			title = "туда"
			            			disabled = {
			            				this.props.state.statistic && this.props.state.statistic.workingCompanies && this.props.state.statistic.workingCompanies.length < this.props.state.statistic.workingCompaniesLimit ? true : false
			            			}
			            			onClick = {this.workingPaging.bind(this, this.props.state.statistic && this.props.state.statistic.hasOwnProperty("workingCompaniesLimit") && this.props.state.statistic.workingCompaniesLimit, this.props.state.statistic && this.props.state.statistic.hasOwnProperty("workingCompaniesOffset") && this.props.state.statistic.workingCompaniesOffset + this.props.state.statistic.workingCompaniesLimit)}
		            			>
		            				<ArrowForward/>
			            		</IconButton>
			          		</TableRowColumn>
			          	</TableRow>
			          </TableBody>
							</Table>
					</div>
					] :
					<div style = {partStyle}>
						<SelectField
		          floatingLabelText="Период"
		          value={this.props.state.statistic && this.props.state.statistic.dataPeriod != undefined ? +this.props.state.statistic.dataPeriod : +this.state.dataPeriod}
		          onChange={this.changeDataPeriod}
		          autoWidth = {true}
		        >
		        	<MenuItem value = {3} primaryText = "Все время" />
		        	<MenuItem value = {2} primaryText = "Год" />
		        	<MenuItem value = {1} primaryText = "Месяц" />
		        	<MenuItem value = {0} primaryText = "Неделя" />
		        	<MenuItem value = {4} primaryText = "Вчера" />
		        	<MenuItem value = {5} primaryText = "Сегодня" />
		        	<MenuItem value = {6} primaryText = "Собственный" />
		        </SelectField>
		        <SelectField
		          floatingLabelText="Подходят для банков"
		          value={this.props.state.statistic && this.props.state.statistic.dataBanks}
		          onChange={this.changeDataBanks}
		          autoWidth = {true}
		          multiple = {true}
		          floatingLabelFixed = {true}
		          selectionRenderer = {values => values.length == 0 ? "Не подходит ни к одному" : values.length == 1 ? this.props.state.banks.find(bank => bank.id == values[0]).name : `Выбрано банков: ${values.length}`}
		        >
		        	{this.props.state.banks && this.props.state.banks.map((bank, key) => (
		        		<MenuItem value = {bank.id} primaryText = {bank.name} key = {key} />
		        	))}
		        </SelectField>
		        <Checkbox 
		        	label = "Только свободные"
		        	checked = {this.props.state.statistic && this.props.state.statistic.dataFree != undefined ? (+this.props.state.statistic.dataFree ? true : false) : this.state.dataFree}
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
		        		this.props.state.statistic && this.props.state.statistic.data && this.props.state.statistic.data.length > 0 ? this.props.state.statistic.data.map(i => i.companies).reduce((before, after) => before + after) : 0
		        	}
		        	{" компаний за период: "}
		        	{
		        		(this.props.state.statistic && this.props.state.statistic.dataPeriod != 6) ?
		        		(
		        			this.props.state.statistic.data && this.props.state.statistic.data.length > 0 && (this.props.state.statistic.data.map(i => i.date).filter((item, key, self) => self.indexOf(item) == key).length == 1 ? this.props.state.statistic.data[0].date : `${this.props.state.statistic.data[0].date} – ${this.props.state.statistic.data[this.props.state.statistic.data.length - 1].date}`)
		        		) :
		        		[<DatePicker 
		  						key = {0}
		  						floatingLabelText="Начальная дата"
		  						style = {datePickerStyle}
		  						defaultDate = {
		  							this.props.state.statistic ? 
		  								new Date(this.props.state.statistic.dataDateStart) :
		  								new Date()
		  						}
		  						onChange = {(eny, date) => {
		  							this.changeDataDate(date, 1);
		  						}}
		  					/>, 
		  					" — ",
		  					<DatePicker 
		  						key = {1}
		  						floatingLabelText="Конечная дата"
		  						style = {datePickerStyle}
		  						defaultDate = {
		  							this.props.state.statistic ? 
		  								new Date(this.props.state.statistic.dataDateEnd) :
		  								new Date()
		  						}
		  						onChange = {(eny, date) => {
		  							this.changeDataDate(date, 0);
		  						}}
		  					/>,
		  					this.props.state.statistic && this.props.state.statistic.data && this.props.state.statistic.data.map(i => i.date).filter((item, key, self) => self.indexOf(item) == key).length == 1 && `(только ${this.props.state.statistic.data[0].date})` || ""]
		        	}
		        </div>
		        {
		        	this.props.state.statistic && this.props.state.statistic.data && this.props.state.statistic.data.length > 0 &&
							<Bar 
								data = {{
							    labels: this.props.state.statistic && this.props.state.statistic.data && (this.props.state.statistic.data.map(i => i.date).filter((item, key, self) => self.indexOf(item) == key).length == 1 ? this.props.state.statistic.data.map(i => i.time).filter((item, key, self) => self.indexOf(item) == key) : this.props.state.statistic.data.map(i => i.date)).filter((item, key, self) => self.indexOf(item) == key) || [],
									datasets: this.props.state.statistic && this.props.state.statistic.data && this.props.state.statistic.data.filter((item, key, self) => self.findIndex(i => i.template_name == item.template_name) == key).map((template, key) => ({
										label: `${template.template_name} (${this.getFormated("data", template.template_name).reduce((before, after) => (before + after))})`,
										backgroundColor: this.state.colors[key][1],
										borderColor: this.state.colors[key][0],
										pointHoverBackgroundColor: this.state.colors[key][0],
										pointHoverBorderColor: 'rgba(220,220,220,1)',
										data: this.getFormated("data", template.template_name)
									}))
								}}
								options = {{
									scales: {
				            yAxes: [{
			                ticks: {
		                    beginAtZero:true,
		                    stacked: false
			                }			        
				            }]
					        },
					        tooltips: {
					        	intersect: false,
					        	position: "nearest"
					        }
								}}
							/>
		        }
					</div>
			}
			<div style={{textAlign: "center", marginBottom: "20px"}}>
				Для подписки на информацию по заливкам и обработке компаний напишите любое сообщение в telegram (<a href = "https://t.me/zakupkiInfoBot" target="_blank">@zakupkiInfoBot</a>)
			</div>
		</div>
	}
}