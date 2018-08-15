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
		this.changeTypeToView = this.changeTypeToView.bind(this);
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
						typeToView: payload,
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
				query: "setBankStatisticFilter",
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
				query: "setBankStatisticFilter",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify({
						user: payload,
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
				query: "setBankStatisticFilter",
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
				query: "setBankStatisticFilter",
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
		});
		this.resetStatisticArr("data");
	}
	changeDate(date, dateStartBool){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setBankStatisticFilter",
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
				query: "setBankStatisticFilter",
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
	getFormated(type, template){
		let arr = this.props.state.statistic[type].filter(item => item.template_name == template) || [],
				datesArr = this.props.state.statistic[type].filter((item, key, self) => self.findIndex(i => i.date == item.date) == key).map(i => i.date),
	 			newArr = datesArr.length > 1 ? datesArr.map(item => arr.filter(i => i.date == item)).map(item => item.length > 0 ? item.reduce((before, after) => ({companies: before.companies + after.companies})).companies : 0) : datesArr.length == 1 ? arr.map(item => item.companies) : [];
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
				query: "setBankStatisticFilter",
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
	          value={this.props.state.statistic && this.props.state.statistic.typeToView != undefined ? +this.props.state.statistic.typeToView : +this.state.typeToView}
	          onChange={this.changeTypeToView}
	          autoWidth = {true}
	        >
	        	<MenuItem value = {0} primaryText = "Все" />
	        	<Divider/>
	        	<MenuItem value = {7} primaryText = "Утвержденные все" />
	        	<MenuItem value = {2} primaryText = "Утвержденные в обработке" />
	        	<MenuItem value = {1} primaryText = "Утвержденные с ошибкой все" />
	        	<MenuItem value = {20} primaryText = "Утвержденные с ошибкой запросе" />
	        	<MenuItem value = {11} primaryText = "Утвержденные дубликаты" />
	        	<MenuItem value = {18} primaryText = "Утвержденные с отказом банка" />
	        	<MenuItem value = {19} primaryText = "Утвержденные с отказом клиента" />
	        	<MenuItem value = {3} primaryText = "Утвержденные успешные все" />
	        	<MenuItem value = {21} primaryText = "Утвержденные с успехом в запросе" />
	        	<MenuItem value = {12} primaryText = "Утвержденные со сбором документов" />
	        	<MenuItem value = {13} primaryText = "Утвержденные с обработкой комплекта" />
	        	<MenuItem value = {14} primaryText = "Утвержденные с назначением встречи" />
	        	<MenuItem value = {15} primaryText = "Утвержденные с назначенной встречей" />
	        	<MenuItem value = {16} primaryText = "Утвержденные в постобработке" />
	        	<MenuItem value = {17} primaryText = "Утвержденные с открытым счетом" />
	        	<Divider/>
	        	<MenuItem value = {9} primaryText = "Обработанные все" />
	        	<MenuItem value = {4} primaryText = "Обработанные интересные" />
	        	<MenuItem value = {5} primaryText = "Обработанные не интересные" />
	        	<MenuItem value = {8} primaryText = "Обработанные не утвержденные" />
	        	<MenuItem value = {10} primaryText = "Обработанные на перезвон" />
	        	<MenuItem value = {22} primaryText = "Обработанные на первичном недозвоне" />
	        	<MenuItem value = {23} primaryText = "Обработанные на вторичном недозвоне" />
	        	<MenuItem value = {24} primaryText = "Обработанные сложные" />
	        	<Divider/>
	        	<MenuItem value = {6} primaryText = "Необработанные в работе" />
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
	          value={this.props.state.statistic && this.props.state.statistic.user != undefined ? +this.props.state.statistic.user : this.state.user}
	          onChange={this.changeUser}
	          autoWidth = {true}
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
								  	label: template.template_name,
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
		        <Checkbox 
		        	label = "Подходящие для Банка"
		        	checked = {this.props.state.statistic && this.props.state.statistic.dataBank != undefined ? (+this.props.state.statistic.dataBank ? true : false) : this.state.dataBank}
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
										label: template.template_name,
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