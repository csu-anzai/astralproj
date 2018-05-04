import React from 'react';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';
import Restore from 'material-ui/svg-icons/action/restore';
import Favorite from 'material-ui/svg-icons/action/favorite';
import HighlightOff from 'material-ui/svg-icons/action/highlight-off';
import Check from 'material-ui/svg-icons/navigation/check';
import DeleteForever from 'material-ui/svg-icons/action/delete-forever';
import CheckCircle from 'material-ui/svg-icons/action/check-circle';
import Info from 'material-ui/svg-icons/action/info';
import Phone from 'material-ui/svg-icons/communication/phone';
import Paper from 'material-ui/Paper';
import RaisedButton from 'material-ui/RaisedButton';
import IconButton from 'material-ui/IconButton';
import FlatButton from 'material-ui/FlatButton';
import { Redirect } from 'react-router';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import DatePicker from 'material-ui/DatePicker';
import TimePicker from 'material-ui/TimePicker';
import Dialog from 'material-ui/Dialog';
import TextField from 'material-ui/TextField';
import {
  Table,
  TableBody,
  TableFooter,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn,
} from 'material-ui/Table';
const datePickerStyle = {
	display: "inline-block",
	verticalAlign: "bottom"
};
export default class Tinkoff extends React.Component {
	constructor(props){
		super(props);
		const date = new Date();
		this.state = {
			selectedIndex: 0,
			limit: 10,
			hash: localStorage.getItem("hash"),
			companyID: 0,
			dialog: false,
			comment: "",
			companyOrganization: "",
			dialogType: 1,
			dateCallBack: new Date(),
			timeCallBack: new Date()
		};
		this.refresh = this.refresh.bind(this);
		this.setDistributionFilter = this.setDistributionFilter.bind(this);
		this.closeDialog = this.closeDialog.bind(this);
		this.sendToApi = this.sendToApi.bind(this);
		this.comment = this.comment.bind(this);
	}
	select(index){
		this.setState({
			selectedIndex: index
		});
	};
	refresh(){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "getBankCompanies",
				priority: true,
				values: [
					this.props.state.connectionHash,
					1,
					this.state.limit
				]
			}
		});
	}
	reset(type_id){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "resetCompanies",
				priority: true,
				values: [
					this.props.state.connectionHash,
					type_id
				]
			}
		});
	}
	sendToApi(){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "sendToApi",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify(this.state.companyID),
					this.state.comment
				]
			}
		});
		this.closeDialog();
	}
	changeType(company_id, type_id, dateArr){
		let date, time;
		if (dateArr && dateArr instanceof Array){
			date = dateArr[0];
			time = dateArr[1];
		}
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setCompanyType",
				priority: true,
				values: [
					this.props.state.connectionHash,
					company_id,
					type_id,
					(date && time) ? `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${time.getHours()}:${time.getMinutes()}:00` : null
				]
			}
		});
		if(type_id == 23){
			this.closeDialog();
		}
	}
	setDistributionFilter(filters){
		let filterName = Object.keys(filters)[0];
		if (filters[filterName].type == 6 && !filters[filterName].hasOwnProperty("dateStart") && !filters[filterName].hasOwnProperty("endStart")){
			filters[filterName].dateStart = this.props.state.distribution[filterName].dateStart;
			filters[filterName].dateEnd = this.props.state.distribution[filterName].dateEnd;
		}
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setDistributionFilter",
				values: [
					this.props.state.connectionHash,
					JSON.stringify(filters)
				]
			}
		});
	}
	componentDidMount(){
		let component = document.querySelector("#app > div > div:nth-child(2) > div > div:nth-child(2) > div");
		component && (component.style.overflow = "auto");
	}
	companyCheck(companyID, organizationName, dialogType){
		if (dialogType == 1){
			const date = new Date();
			this.setState({
				dateCallBack: date,
				timeCallBack: date
			});
		}
		this.setState({
			companyID: companyID,
			dialog: true,
			dialogType,
			companyOrganization: organizationName
		});
	}
	closeDialog(){
		this.setState({
			dialog: false,
			comment: "",
			companyID: 0,
			companyOrganization: ""
		});
	}
	comment(text){
		this.setState({
			comment: text
		});
	}
	render(){
		localStorage.removeItem("hash");
		return (this.state.hash == "/" || this.state.hash == "/tinkoff" || !this.state.hash) && <div>
			<Paper zDepth={0}>
				<BottomNavigation selectedIndex={this.state.selectedIndex}>
					<BottomNavigationItem
            label={"В РАБОТЕ ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 10 || i.type_id == 9).length || 0)+")"}
            icon={<Restore/>}
            onClick={() => this.select(0)}
          />
          <BottomNavigationItem
            label={"НЕ ИНТЕРЕСНО ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 14).length || 0)+")"}
            icon={<HighlightOff/>}
            onClick={() => this.select(1)}
          />
          <BottomNavigationItem
            label={"УТВЕРЖДЕНО ("+(this.props.state.companies && this.props.state.companies.filter(i => [15,16,17,24,25,26,27,28,29,30,31,32].indexOf(i.type_id) > -1).length || 0)+")"}
            icon={<CheckCircle/>}
            onClick={() => this.select(2)}
          />
          <BottomNavigationItem
            label={"ПЕРЕЗВОНИТЬ ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 23).length || 0)+")"}
            icon={<Phone/>}
            onClick={() => this.select(3)}
          />
				</BottomNavigation>
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
	              <TableHeaderColumn colSpan={this.state.selectedIndex == 2 ? "9" : "8"}>
	              	<div>
		              	<span style = {{
		              		display: "inline-block",
		              		height: "36px",
		              		lineHeight: this.state.selectedIndex == 0 ? "36px" : "100px",
		              		fontWeight: "bold",
		              		fontSize: "14px",
		              		color: this.props.state.messageType == "success" ? "#789a0a" : this.props.state.messageType == "error" ? "#ff4081" : "inherit"
		              	}}>
		              		{ this.props.state.message }
		              	</span>
		              	<div style = {{float: "right"}}>
		              		{
		              			this.props.state.distribution && 
		              			this.props.state.distribution[
              						this.state.selectedIndex == 1 && "invalidate" ||
              						this.state.selectedIndex == 2 && "api" ||
              						this.state.selectedIndex == 3 && "callBack"
              					] && this.props.state.distribution[
              						this.state.selectedIndex == 1 && "invalidate" ||
              						this.state.selectedIndex == 2 && "api" ||
              						this.state.selectedIndex == 3 && "callBack"
              					].type == 6 && [
	              					<DatePicker 
	              						key = {0}
	              						floatingLabelText="Начальная дата"
	              						style = {datePickerStyle}
	              						defaultDate = {
	              							new Date(this.props.state.distribution[
	              								this.state.selectedIndex == 1 && "invalidate" ||
	              								this.state.selectedIndex == 2 && "api" ||
	              								this.state.selectedIndex == 3 && "callBack"
	              							].dateStart)
	              						}
	              						onChange = {(eny, date) => {
	              							this.setDistributionFilter({
	              								[
	              									this.state.selectedIndex == 1 && "invalidate" ||
	              									this.state.selectedIndex == 2 && "api" ||
	              									this.state.selectedIndex == 3 && "callBack"
	              								]: {
	              									dateStart: `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`,
	              									dateEnd: this.props.state.distribution[
			              								this.state.selectedIndex == 1 && "invalidate" ||
			              								this.state.selectedIndex == 2 && "api" ||
			              								this.state.selectedIndex == 3 && "callBack"
			              							].dateEnd,
	              									type: 6
	              								}
	              							});
	              						}}
	              					/>,
	              					<DatePicker
	              						key = {1} 
	              						floatingLabelText="Конечная дата"
	              						style = {datePickerStyle}
	              						defaultDate = {
	              							new Date(this.props.state.distribution[
	              								this.state.selectedIndex == 1 && "invalidate" ||
	              								this.state.selectedIndex == 2 && "api" ||
	              								this.state.selectedIndex == 3 && "callBack"
	              							].dateEnd)
	              						}
	              						onChange = {(eny, date) => {
	              							this.setDistributionFilter({
	              								[
	              									this.state.selectedIndex == 1 && "invalidate" ||
	              									this.state.selectedIndex == 2 && "api" ||
	              									this.state.selectedIndex == 3 && "callBack"
	              								]: {
	              									dateEnd: `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`,
	              									dateStart: this.props.state.distribution[
			              								this.state.selectedIndex == 1 && "invalidate" ||
			              								this.state.selectedIndex == 2 && "api" ||
			              								this.state.selectedIndex == 3 && "callBack"
			              							].dateStart,
	              									type: 6
	              								}
	              							});
	              						}}
	              					/>
	              				]
		              		}
		              		{
		              			(this.state.selectedIndex == 1 || this.state.selectedIndex == 2 || this.state.selectedIndex == 3) &&
		              			<SelectField
		              				floatingLabelText = "Период"
		              				value = {
		              					this.props.state.distribution && 
		              					this.props.state.distribution[
		              						this.state.selectedIndex == 1 && "invalidate" ||
		              						this.state.selectedIndex == 2 && "api" ||
		              						this.state.selectedIndex == 3 && "callBack"
		              					].type
		              				}
		              				style = {{
		              					verticalAlign: "bottom"
		              				}}
		              				onChange = {(e, k, data) => {
		              					this.setDistributionFilter({
		              						[
		              							this.state.selectedIndex == 1 && "invalidate" ||
			              						this.state.selectedIndex == 2 && "api" ||
			              						this.state.selectedIndex == 3 && "callBack"
		              						]: {
		              							type: data
		              						}
		              					});
		              				}}
		              				autoWidth = {true}
		              			>
		              				<MenuItem value = {0} primaryText = "Сегодня"/>
		              				<MenuItem value = {5} primaryText = "Вчера"/>
		              				<MenuItem value = {1} primaryText = "Неделя"/>
		              				<MenuItem value = {2} primaryText = "Месяц"/>
		              				<MenuItem value = {3} primaryText = "Год"/>
		              				<MenuItem value = {4} primaryText = "Все время"/>
		              				<MenuItem value = {6} primaryText = "Собственный период"/>
		              			</SelectField>
		              		}
			              	{
			              		this.state.selectedIndex == 0 &&
				                <RaisedButton 
				                	label = "Обновить список"
				                	backgroundColor="#a4c639"
				                	labelColor = "#fff"
				                	onClick = {this.refresh}
				                />
				              }
				              {
				              	(this.state.selectedIndex == 1 || this.state.selectedIndex == 3) &&
				              	<FlatButton 
				                	label = "Сбросить список"
				                	primary
				                	onClick = {this.reset.bind(this, this.state.selectedIndex == 1 ? 14 : 23)}
				                	style = {{
				                		marginBottom: "8px"
				                	}}
				                />
				              }
		              	</div>
	              	</div>
	              </TableHeaderColumn>
	            </TableRow>
	            <TableRow>
	              <TableHeaderColumn>Телефон</TableHeaderColumn>
	              <TableHeaderColumn>Тип компании</TableHeaderColumn>
	              <TableHeaderColumn>ИНН</TableHeaderColumn>
	              <TableHeaderColumn>Регион</TableHeaderColumn>
	              <TableHeaderColumn>Город</TableHeaderColumn>
	              <TableHeaderColumn>Название компании</TableHeaderColumn>
	              <TableHeaderColumn>Ф.И.О</TableHeaderColumn>
	              {
	              	this.state.selectedIndex == 2 &&
	              	<TableHeaderColumn>Коментарий</TableHeaderColumn>
	              }
	              {
	              	this.state.selectedIndex == 3 && 
	              	<TableHeaderColumn>Дата и Время</TableHeaderColumn>
	              }
              	<TableHeaderColumn>{this.state.selectedIndex != 2 ? "Действия" : "Статус обработки"}</TableHeaderColumn>
	            </TableRow>
	          </TableHeader>
	          <TableBody
	            displayRowCheckbox={false}
	            deselectOnClickaway={false}
	            showRowHover={this.state.showRowHover}
	            stripedRows={this.state.stripedRows}
	          >
	          	{
	          		this.props.state.companies && this.props.state.companies.length > 0 && this.props.state.companies.map((company, key) => (
		              (
		              	(this.state.selectedIndex == 0 && (company.type_id == 10 || company.type_id == 9)) || 
		              	(this.state.selectedIndex == 1 && company.type_id == 14) || 
		              	(this.state.selectedIndex == 2 && [15,16,17,24,25,26,27,28,29,30,31,32].indexOf(company.type_id) > -1) ||
		              	(this.state.selectedIndex == 3 && company.type_id == 23)
		              ) &&
		              <TableRow key = {key}>
		                <TableRowColumn>{company.company_phone || "–"}</TableRowColumn>
		                <TableRowColumn>{company.template_id == 1 ? "ИП" : "ООО"}</TableRowColumn>
		                <TableRowColumn>{company.company_inn || "–"}</TableRowColumn>
		                <TableRowColumn>{company.region_name || "–"}</TableRowColumn>
		                <TableRowColumn>{company.city_name || "–"}</TableRowColumn>
		                <TableRowColumn style={{whiteSpace: "normal"}}>{company.company_organization_name || "–"}</TableRowColumn>
		                <TableRowColumn style={{whiteSpace: "normal"}}>{`${company.company_person_name} ${company.company_person_surname} ${company.company_person_patronymic}`.split("null").join("")}</TableRowColumn>
		                {
		                	this.state.selectedIndex == 2 &&
		                	<TableRowColumn style={{whiteSpace: "normal"}}>{company.company_comment || "–"}</TableRowColumn>
		                }
		                {
		                	this.state.selectedIndex == 3 &&
		                	<TableRowColumn>{company.company_date_call_back || "–"}</TableRowColumn>
		                }
		                { 
		                	<TableRowColumn>
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 1 || this.state.selectedIndex == 3) &&
				                	<IconButton
				                		title="Оформить заявку"
				                		onClick = {this.companyCheck.bind(this, company.company_id, company.company_organization_name, 0)}
				                	>
				                		<Check color = "#a4c639"/>
				                	</IconButton>
		                		}
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 1) && 
		                			<IconButton
		                				title="Перезвонить"
				                		onClick = {this.companyCheck.bind(this, company.company_id, company.company_organization_name, 1)}
				                	>
				                		<Phone color = "#EF6C00"/>
				                	</IconButton>
		                		}
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 3) &&
				                	<IconButton
				                		title="Не интересно"
				                		onClick = {this.changeType.bind(this, company.company_id, 14)}
				                	>
				                		<DeleteForever color = "#E53935"/>
				                	</IconButton>
		                		}
		                		{
		                			this.state.selectedIndex == 2 &&
		                			<span style = {{
		                				color: company.type_id == 15 ? "inherit" : [16,25,26,27,28,29,30].indexOf(company.type_id) > -1 ? "green" : [17,24,31,32].indexOf(company.type_id) > -1 && "red"
		                			}}>
		                				{
				                			company.type_id == 15 ? "В процессе" :
				                			company.type_id == 16 ? "Успешно" :
				                			company.type_id == 17 ? "Ошибка" :
				                			company.type_id == 24 ? "Дубликат" :
				                			company.type_id == 25 ? "Сбор документов" :
				                			company.type_id == 26 ? "Обработка комплекта" :
				                			company.type_id == 27 ? "Назначение встречи" :
				                			company.type_id == 28 ? "Встреча назначена" :
				                			company.type_id == 29 ? "Постобработка" :
				                			company.type_id == 30 ? "Счет открыт" :
				                			company.type_id == 31 ? "Отказ Банка" :
				                			company.type_id == 32 && "Отказ клиента"
		                				}
		                			</span>
		                		}
			                </TableRowColumn>
		                }
		              </TableRow>
	          		)) || 
	          		<TableRow>
	          			<TableRowColumn 
	          				colSpan = "8"
	          				style = {{
	          					textAlign: "center"
	          				}}
	          			>
	          				Нет загруженых записей
	          			</TableRowColumn>
	          		</TableRow>
	          	}
	          </TableBody>
        </Table>
        <Dialog
          title={
          	this.state.dialogType == 0 ? 
          		`Оформление заявки – ${this.state.companyOrganization}` : 
          		this.state.dialogType == 1 && 
          			`Выбор даты и времени – ${this.state.companyOrganization}`
          }
          actions={[
			      <FlatButton
			        label="Отменить"
			        secondary
			        onClick={this.closeDialog}
			      />,
			      <FlatButton
			        label="Отправить"
			        primary
			        onClick={
			        	this.state.dialogType == 0 ? 
			        		this.sendToApi : 
			        		this.changeType.bind(this, this.state.companyID, 23, [this.state.dateCallBack, this.state.timeCallBack])
			        }
			      />,
			    ]}
          modal={false}
          open={this.state.dialog}
          onRequestClose={this.closeDialog}
        >
        	{
        		this.state.dialogType == 0 ?
		          <TextField
					      floatingLabelText="Коментарий к заявке"
					      multiLine={true}
					      fullWidth={true}
					      rows={5}
					      rowsMax={10}
					     	onChange = {(event, text) => {
					     		this.comment(text)
					     	}}
			    		/> :
			    		this.state.dialogType == 1 &&
			    			<div>
				    			<DatePicker 
				    				floatingLabelText="Выбор даты"
				    				minDate={new Date()}
				    				defaultDate={new Date()}
				    				onChange = {(eny, date) => {
							     		this.setState({
							     			dateCallBack: date
							     		});
							     	}}
				    			/>
				    			<TimePicker
							      hintText="Выбор времени"
							      defaultTime={new Date()}
							      onChange = {(event, date) => {
							      	this.setState({
							      		timeCallBack: date
							      	});
							      }}
							    />
							    <div style = {{fontSize: "12px"}}>
							    		<Info style={{verticalAlign: "middle", width: "25px", color: "#e8a521"}}/> Время и дата не должны быть меньше текущих даты и времени
							    </div>
			    			</div>
        	}
        </Dialog>
			</Paper>
		</div> ||
		<Redirect to = {this.state.hash} />
	}
}