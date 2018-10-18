import React from 'react';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';
import Divider from 'material-ui/Divider';
import Restore from 'material-ui/svg-icons/action/restore';
import Favorite from 'material-ui/svg-icons/action/favorite';
import HighlightOff from 'material-ui/svg-icons/action/highlight-off';
import Check from 'material-ui/svg-icons/navigation/check';
import DeleteForever from 'material-ui/svg-icons/action/delete-forever';
import CheckCircle from 'material-ui/svg-icons/action/check-circle';
import Info from 'material-ui/svg-icons/action/info';
import Phone from 'material-ui/svg-icons/communication/phone';
import CallEnd from 'material-ui/svg-icons/communication/call-end';
import DialerSip from 'material-ui/svg-icons/communication/dialer-sip';
import SadFace from 'material-ui/svg-icons/social/sentiment-dissatisfied';
import History from 'material-ui/svg-icons/action/history';
import ArrowBack from 'material-ui/svg-icons/navigation/arrow-back';
import ArrowForward from 'material-ui/svg-icons/navigation/arrow-forward';
import Audiotrack from 'material-ui/svg-icons/image/audiotrack';
import PhoneForwarded from 'material-ui/svg-icons/notification/phone-forwarded';
import PhoneInTalk from 'material-ui/svg-icons/notification/phone-in-talk';
import RemoveCircle from 'material-ui/svg-icons/content/remove-circle';
import SettingsPhone from 'material-ui/svg-icons/action/settings-phone';
import Replay from 'material-ui/svg-icons/av/replay';
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
import CircularProgress from 'material-ui/CircularProgress';
import Checkbox from 'material-ui/Checkbox';
import AppBar from 'material-ui/AppBar';
import NavigationClose from 'material-ui/svg-icons/navigation/close';
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
const categories = [
	"work",
	"invalidate",
	"api",
	"callBack",
	"notDial",
	"difficult"
];
const categoriesTypes = [
	[35,9],
	[14],
	[15,16,17,24,25,26,27,28,29,30,31,32],
	[23],
	[36],
	[37]
];
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
			companyBank: 0,
			dialogType: 1,
			dateCallBack: new Date(),
			timeCallBack: new Date(),
			workDialog: true
		};
		this.refresh = this.refresh.bind(this);
		this.setDistributionFilter = this.setDistributionFilter.bind(this);
		this.closeDialog = this.closeDialog.bind(this);
		this.sendToApi = this.sendToApi.bind(this);
		this.comment = this.comment.bind(this);
		this.ringing = this.ringing.bind(this);
		this.checkCompanies = this.checkCompanies.bind(this);
		this.closeWorkDialog = this.closeWorkDialog.bind(this);
		this.nextCall = this.nextCall.bind(this);
		this.bankSelect = this.bankSelect.bind(this);
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
					this.state.limit,
					1
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
		this.closeDialog();
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
					this.state.comment,
					this.state.companyBank
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
	openDialog(dialogType){
		this.setState({
			dialogType,
			dialog: true
		});
	}
	closeDialog(){
		this.setState({
			dialog: false,
			comment: "",
			companyID: 0,
			companyOrganization: "",
			companyBank: 0
		});
	}
	comment(text){
		this.setState({
			comment: text
		});
	}
	call(company_id){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "callRequest",
				priority: true,
				values: [
					this.props.state.connectionHash,
					company_id,
					1
				]
			}
		})
	}
	nextCall(){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "nextCall",
				priority: true,
				values: [
					this.props.state.connectionHash
				]
			}
		});
	}
	openURL(url){
		window.open(url, "_blank");
	}
	ringing(){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setUserRinging",
				values: [
					this.props.state.connectionHash,
					!this.props.state.ringing
				]
			}
		})
	}
	resetCall(company_id){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "resetCall",
				values: [
					this.props.state.connectionHash,
					company_id
				]
			}
		})
	}
	checkCompanies(){
		this.props.dispatch({
			type: "checkCompaniesStatus",
			socket: true,
			data: {
				user_hash: this.props.state.connectionHash
			}
		});
	}
	deleteCompanyDialog(companyID){
		this.setState({
			companyID
		});
		this.openDialog.call(this,3);
	}
	deleteCompany(companyID){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "deleteCompany",
				values: [
					this.props.state.connectionHash,
					companyID
				]
			}
		});
		this.closeDialog();
	}
	closeWorkDialog(bool){
		this.setState({
			workDialog: !bool || typeof bool == "object" ? false : true
		});
	}
	bankSelect(event, key, payload){
		this.setState({
			companyBank: payload
		});
	}
	render(){
		localStorage.removeItem("hash");
		return (this.state.hash == "/" || this.state.hash == "/tinkoff" || !this.state.hash) && <div>
			<Paper zDepth={0}>
				<BottomNavigation selectedIndex={this.state.selectedIndex}>
					<BottomNavigationItem
            label={"В РАБОТЕ"}
            icon={<Restore/>}
            onClick={() => this.select(0)}
          />
          <BottomNavigationItem
            label={"НЕ ИНТЕРЕСНО"}
            icon={<HighlightOff/>}
            onClick={() => this.select(1)}
          />
          <BottomNavigationItem
            label={"УТВЕРЖДЕНО"}
            icon={<CheckCircle/>}
            onClick={() => this.select(2)}
          />
          <BottomNavigationItem
            label={"ПЕРЕЗВОНИТЬ"}
            icon={<Phone/>}
            onClick={() => this.select(3)}
          />
          <BottomNavigationItem
            label={"НЕТ СВЯЗИ"}
            icon={<CallEnd/>}
            onClick={() => this.select(4)}
          />
          <BottomNavigationItem
            label={"СЛОЖНЫЕ"}
            icon={<SadFace/>}
            onClick={() => this.select(5)}
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
	              <TableHeaderColumn colSpan={this.state.selectedIndex == 3 ? "9" : this.state.selectedIndex == 2 ? "10" : "8"}>
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
              						categories[this.state.selectedIndex]
              					] && this.props.state.distribution[
              						categories[this.state.selectedIndex]
              					].type == 6 && [
	              					<DatePicker 
	              						key = {0}
	              						floatingLabelText="Начальная дата"
	              						style = {datePickerStyle}
	              						defaultDate = {
	              							new Date(this.props.state.distribution[
	              								categories[this.state.selectedIndex]
	              							].dateStart)
	              						}
	              						onChange = {(eny, date) => {
	              							this.setDistributionFilter({
	              								[
	              									categories[this.state.selectedIndex]
	              								]: {
	              									dateStart: `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`,
	              									dateEnd: this.props.state.distribution && this.props.state.distribution[
			              								categories[this.state.selectedIndex]
			              							].dateEnd,
	              									type: 6,
	              									rowLimit: this.props.state.distribution && this.props.state.distribution[
					              						categories[this.state.selectedIndex]
					              					].rowLimit,
					              					rowStart: this.props.state.distribution && this.props.state.distribution[
					              						categories[this.state.selectedIndex]
					              					].rowStart
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
	              								categories[this.state.selectedIndex]
	              							].dateEnd)
	              						}
	              						onChange = {(eny, date) => {
	              							this.setDistributionFilter({
	              								[
	              									categories[this.state.selectedIndex]
	              								]: {
	              									dateEnd: `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`,
	              									dateStart: this.props.state.distribution && this.props.state.distribution[
			              								categories[this.state.selectedIndex]
			              							].dateStart,
	              									type: 6,
	              									rowLimit: this.props.state.distribution && this.props.state.distribution[
					              						categories[this.state.selectedIndex]
					              					].rowLimit,
					              					rowStart: this.props.state.distribution && this.props.state.distribution[
					              						categories[this.state.selectedIndex]
					              					].rowStart
	              								}
	              							});
	              						}}
	              					/>
	              				]
		              		}
		              		{
		              			[1,2,3,4,5].indexOf(this.state.selectedIndex) != -1 &&
		              			<SelectField
		              				floatingLabelText = "Период"
		              				value = {
		              					this.props.state.distribution && 
		              					this.props.state.distribution[
		              						categories[this.state.selectedIndex]
		              					].type
		              				}
		              				style = {{
		              					verticalAlign: "bottom"
		              				}}
		              				onChange = {(e, k, data) => {
		              					this.setDistributionFilter({
		              						[
		              							categories[this.state.selectedIndex]
		              						]: {
		              							type: data,
		              							rowLimit: this.props.state.distribution && this.props.state.distribution[
				              						categories[this.state.selectedIndex]
				              					].rowLimit,
				              					rowStart: this.props.state.distribution[
				              						categories[this.state.selectedIndex]
				              					].rowStart
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
			              		this.state.selectedIndex == 0 && [
			              			<FlatButton
			              				label = "открыть рабочую область"
			              				onClick = {this.closeWorkDialog.bind(this, 1)}
			              				key = {0}
			              			/>,
					                <RaisedButton 
					                	label = "Обновить список"
					                	backgroundColor="#a4c639"
					                	labelColor = "#fff"
					                	key = {1}
					                	onClick = {this.refresh}
					                />
					              ]
				              }
				              {
				              	(this.state.selectedIndex == 1 || this.state.selectedIndex == 3) &&
				              	<FlatButton 
				                	label = "Сбросить список"
				                	primary
				                	onClick = {this.openDialog.bind(this, 2)}
				                	style = {{
				                		marginBottom: "8px"
				                	}}
				                />
				              }
				              {
		              			this.state.selectedIndex == 2 && 
		              			<FlatButton 
		              				label = "Уточнить статус"	
		              				primary
		              				onClick = {this.checkCompanies}
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
	            	<TableHeaderColumn colSpan={this.state.selectedIndex == 3 ? "9" : this.state.selectedIndex == 2 ? "10" : "8"} style = {{textAlign: "right"}}>
	            		<IconButton 
	            			title = "сюда"
	            			disabled = {
	            				this.props.state.distribution &&
	            				this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							] &&
	            				!(this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							].rowStart == 1) ? false : true
	            			}
	            			onClick = {
	            				this.setDistributionFilter.bind(this, {
	            					[categories[this.state.selectedIndex]]: {
	            						rowLimit: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit,
	              					rowStart: (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowStart) - (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit) - 1 >= 0 ? (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowStart) - (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit) - 1 || 1 : 1,
	              					type: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].type,
	              					dateStart: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateStart,
            							dateEnd: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateEnd
	            					}
	            				})
	            			}
            			>
            				<ArrowBack/>
	            		</IconButton>
	            		<div style = {{
	            			display: "inline-block",
	            			lineHeight: "48px",
	            			verticalAlign: "top"
	            		}}>
	            			{
	            				this.props.state.distribution && 
	            				this.props.state.companies &&
	            				`с ${this.props.state.distribution[
            						categories[this.state.selectedIndex]
            					].rowStart} по ${this.props.state.distribution[
            						categories[this.state.selectedIndex]
            					].rowStart + this.props.state.companies.filter(c => categoriesTypes.findIndex(ct => ct.indexOf(c.type_id) > -1) == this.state.selectedIndex).length - 1 }`
	            			}
	            		</div>
	            		<IconButton 
	            			title = "туда"
	            			disabled = {
	            				(this.props.state.companies &&
	            				this.props.state.distribution &&
	            				this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							] &&
	            				this.props.state.companies.length > 0 &&
	            				this.props.state.companies.filter(company => (
	            					this.state.selectedIndex == 0 ? [9, 35] :
	            					this.state.selectedIndex == 1 ? [14] :
	            					this.state.selectedIndex == 2 ? [15,16,17,24,25,26,27,28,29,30,31,32] :
	            					this.state.selectedIndex == 3 ? [23] :
	            					this.state.selectedIndex == 4 ? [36] :
	            					this.state.selectedIndex == 5 && [37]
            					).indexOf(company.type_id) != -1).length == this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							].rowLimit) ? false : true
	            			}
	            			onClick = {()=>{
	            				this.setDistributionFilter.call(this, {
	            					[categories[this.state.selectedIndex]]: {
	            						rowLimit: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit,
	              					rowStart: (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowStart) + (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit),
	              					type: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].type,
	              					dateStart: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateStart,
            							dateEnd: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateEnd
	            					}
	            				});
	            			}}
            			>
            				<ArrowForward/>
	            		</IconButton>
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
              	{
              		this.state.selectedIndex == 2 &&
	              	<TableHeaderColumn>Действия</TableHeaderColumn>
              	}
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
		              	(this.state.selectedIndex == 0 && [9, 35].indexOf(company.type_id) > -1) || 
		              	(this.state.selectedIndex == 1 && company.type_id == 14) || 
		              	(this.state.selectedIndex == 2 && [15,16,17,24,25,26,27,28,29,30,31,32].indexOf(company.type_id) > -1) ||
		              	(this.state.selectedIndex == 3 && company.type_id == 23) ||
		              	(this.state.selectedIndex == 4 && company.type_id == 36) ||
		              	(this.state.selectedIndex == 5 && company.type_id == 37)
		              ) &&
		              <TableRow key = {key} style = {{background: [33,34,43,38,39].indexOf(company.call_type) > -1 ? "#E8F5E9" : "inherit"}}>
		                <TableRowColumn>{company.company_phone || "–"}</TableRowColumn>
		                <TableRowColumn>{company.template_type_id == 11 ? "ИП" : "ООО"}</TableRowColumn>
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
		                			[0,1,3,4,5].indexOf(this.state.selectedIndex) > -1 &&
		                			(company.call_internal_type_id == 33 && 
		                			company.call_destination_type_id == 33 ?
				                	<CircularProgress 
				                		size = {24} 
				                		color = "#00BFA5" 
				                		title = "Соединение" 
				                		style = {{
				                			padding: "0 12px"
				                		}}
				                	/> :
			                		<IconButton
				                		onClick = {this.call.bind(this, company.company_id)}
				                		title = "Позвонить"
				                		disabled = {
				                			[38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(company.call_internal_type_id) > -1 ||  
				                			[38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(company.call_destination_type_id) > -1 ? 
				                				false : 
				                				true
				                		}
				                	>
				                		{
				                			([38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(company.call_internal_type_id) > -1 ||  
				                			[38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(company.call_destination_type_id) > -1) ?
		                					<DialerSip color = "#00BFA5"/> :
		                					company.call_destination_type_id == 34 ?
		                					<PhoneForwarded color = "#00BFA5"/> :
		                					(company.call_internal_type_id == 39 ||
		                					company.call_destination_type_id == 39) ?
		                					<PhoneInTalk color = "#00BFA5"/> :
				                			([33,43,34].indexOf(company.call_internal_type_id) > -1 ||  
				                			[33,43].indexOf(company.call_destination_type_id) > -1) &&
		                					<SettingsPhone color = "#00BFA5"/>
				                		}
				                	</IconButton>)
		                		}
		                		{
		                			[0,1,3,4,5].indexOf(this.state.selectedIndex) > - 1 &&
		                			([34,39,33,43].indexOf(company.call_internal_type_id) > -1 ||  
		                			[34,39,33,43].indexOf(company.call_destination_type_id) > -1) &&
		                			<IconButton
		                				title = "Сбросить статус звонока"
		                				onClick = {this.resetCall.bind(this, company.company_id)}
		                			>
		                				<Replay color = "#bd38c1"/>
		                			</IconButton>
		                		}
		                		{
		                			[0,1,3,4,5].indexOf(this.state.selectedIndex) > -1 &&
				                	<IconButton
				                		title="Оформить заявку"
				                		onClick = {this.companyCheck.bind(this, company.company_id, company.company_organization_name, 0)}
				                	>
				                		<Check color = "#a4c639"/>
				                	</IconButton>
		                		}
		                		{
		                			[0,1,4,5].indexOf(this.state.selectedIndex) > -1 && 
		                			<IconButton
		                				title="Перезвонить"
				                		onClick = {this.companyCheck.bind(this, company.company_id, company.company_organization_name, 1)}
				                	>
				                		<Phone color = "#EF6C00"/>
				                	</IconButton>
		                		}
		                		{
		                			[0,1,4,5].indexOf(this.state.selectedIndex) > -1 && 
		                			<IconButton
		                				title={company.type_id == 35 ? "Нет связи" : "Переместить в конец рабочего списка"}
				                		onClick = {this.changeType.bind(this, company.company_id, company.type_id == 35 ? 36 : 35)}
				                	>
				                		{
				                			company.type_id == 35 ?
				                			<CallEnd color = "#C51162"/> :
				                			<History color = "#283593"/>
				                		}
				                	</IconButton>
		                		}
		                		{
		                			[0,3,4,5].indexOf(this.state.selectedIndex) > -1 &&
				                	<IconButton
				                		title="Не интересно"
				                		onClick = {this.changeType.bind(this, company.company_id, 14)}
				                	>
				                		<DeleteForever color = "#E53935"/>
				                	</IconButton>
		                		}
		                		{
		                			[0,1,3,4].indexOf(this.state.selectedIndex) > -1 &&
				                	<IconButton
				                		title="Сложный клиент"
				                		onClick = {this.changeType.bind(this, company.company_id, 37)}
				                	>
				                		<SadFace color = "#607D8B"/>
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
		                		{
		                			[0,1,3,4,5].indexOf(this.state.selectedIndex) > -1 &&
		                			company.file_name &&
		                			<IconButton
				                		title="Прослушать последнюю запись"
				                		onClick={this.openURL.bind(this, company.file_name)}
				                	>
				                		<Audiotrack color = "#9575CD"/>
				                	</IconButton>
		                		}
		                		{
		                			[0,1,3,4,5].indexOf(this.state.selectedIndex) > -1 &&
			                		<IconButton
					                	title = "Удалить компанию"
					                	onClick = {this.deleteCompanyDialog.bind(this, company.company_id)}
					                >
					                	<RemoveCircle color = "#9a2c2c"/>
					                </IconButton>
					              }
			                </TableRowColumn>
		                }
		                {
		                	this.state.selectedIndex == 2 &&
		                	<TableRowColumn>
		                		{
		                			company.file_name &&
			                		<IconButton
				                		title="Прослушать последнюю запись"
				                		onClick={this.openURL.bind(this, company.file_name)}
				                	>
				                		<Audiotrack color = "#9575CD"/>
				                	</IconButton>
		                		}
		                		{
		                			([34,39,33,43].indexOf(company.call_internal_type_id) > -1 ||  
		                			[34,39,33,43].indexOf(company.call_destination_type_id) > -1) &&
		                			<IconButton
		                				title = "Сбросить статус звонока"
		                				onClick = {this.resetCall.bind(this, company.company_id)}
		                			>
		                				<Replay color = "#bd38c1"/>
		                			</IconButton>
		                		}
		                		<IconButton
				                	title = "Удалить компанию"
				                	onClick = {this.deleteCompanyDialog.bind(this, company.company_id)}
				                >
					                	<RemoveCircle color = "#9a2c2c"/>
				                </IconButton>
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
	          	<TableRow>
	            	<TableHeaderColumn colSpan={this.state.selectedIndex == 3 ? "9" : this.state.selectedIndex == 2 ? "10" : "8"} style = {{textAlign: "right"}}>
	            		<IconButton 
	            			title = "сюда"
	            			disabled = {
	            				this.props.state.distribution &&
	            				this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							] &&
	            				!(this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							].rowStart == 1) ? false : true
	            			}
	            			onClick = {
	            				this.setDistributionFilter.bind(this, {
	            					[categories[this.state.selectedIndex]]: {
	            						rowLimit: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit,
	              					rowStart: (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowStart) - (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit) - 1 >= 0 ? (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowStart) - (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit) - 1 || 1 : 1,
	              					type: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].type,
	              					dateStart: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateStart,
            							dateEnd: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateEnd
	            					}
	            				})
	            			}
            			>
            				<ArrowBack/>
	            		</IconButton>
	            		<div style = {{
	            			display: "inline-block",
	            			lineHeight: "48px",
	            			verticalAlign: "top"
	            		}}>
	            			{
	            				this.props.state.distribution && 
	            				this.props.state.companies &&
	            				`с ${this.props.state.distribution[
            						categories[this.state.selectedIndex]
            					].rowStart} по ${this.props.state.distribution[
            						categories[this.state.selectedIndex]
            					].rowStart + this.props.state.companies.filter(c => categoriesTypes.findIndex(ct => ct.indexOf(c.type_id) > -1) == this.state.selectedIndex).length - 1 }`
	            			}
	            		</div>
	            		<IconButton 
	            			title = "туда"
	            			disabled = {
	            				(this.props.state.companies &&
	            				this.props.state.distribution &&
	            				this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							] &&
	            				this.props.state.companies.length > 0 &&
	            				this.props.state.companies.filter(company => (
	            					this.state.selectedIndex == 0 ? [9, 35] :
	            					this.state.selectedIndex == 1 ? [14] :
	            					this.state.selectedIndex == 2 ? [15,16,17,24,25,26,27,28,29,30,31,32] :
	            					this.state.selectedIndex == 3 ? [23] :
	            					this.state.selectedIndex == 4 ? [36] :
	            					this.state.selectedIndex == 5 && [37]
            					).indexOf(company.type_id) != -1).length == this.props.state.distribution[
        								categories[this.state.selectedIndex]
        							].rowLimit) ? false : true
	            			}
	            			onClick = {()=>{
	            				this.setDistributionFilter.call(this, {
	            					[categories[this.state.selectedIndex]]: {
	            						rowLimit: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit,
	              					rowStart: (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowStart) + (this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].rowLimit),
	              					type: this.props.state.distribution && this.props.state.distribution[
	              						categories[this.state.selectedIndex]
	              					].type,
	              					dateStart: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateStart,
            							dateEnd: this.props.state.distribution && this.props.state.distribution[
            								categories[this.state.selectedIndex]
            							].dateEnd
	            					}
	            				});
	            			}}
            			>
            				<ArrowForward/>
	            		</IconButton>
	            	</TableHeaderColumn>
	            </TableRow>
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
			        label= {this.state.dialogType == 2 ? "Сбросить" : "Отправить"}
			        primary
			        disabled = {(this.state.dialogType == 0 && this.state.companyBank == 0) ? true : false}
			        onClick={
			        	this.state.dialogType == 0 ? 
			        		this.sendToApi :
			        		this.state.dialogType == 1 ? 
			        			this.changeType.bind(this, this.state.companyID, 23, [this.state.dateCallBack, this.state.timeCallBack]) :
			        			this.state.dialogType == 2 ?
			        				this.reset.bind(this, this.state.selectedIndex == 1 ? 14 : 23) :
			        				this.deleteCompany.bind(this, this.state.companyID)
			        }
			      />,
			    ]}
          modal={false}
          open={this.state.dialog}
          onRequestClose={this.closeDialog}
        >
        	{
        		this.state.dialogType == 0 ?
		          [
		          	<TextField
						      floatingLabelText="Коментарий к заявке"
						      multiLine={true}
						      fullWidth={true}
						      rows={5}
						      rowsMax={10}
						     	onChange = {(event, text) => {
						     		this.comment(text)
						     	}}
						     	key = {0}
				    		/>,
				    		<SelectField
				    			floatingLabelText="Выбор банка"
				    			value = {this.state.companyBank}
				    			errorText = {this.state.companyBank == 0 && "Необходимо выбрать банк"}
				    			onChange = {this.bankSelect}
				    			key = {1}
				    		>
				    			<MenuItem value={1} primaryText="Тинькофф" />
				    			<MenuItem value={2} primaryText="Модуль" />
				    			<MenuItem value={3} primaryText="Промсвязь" />
				    			<MenuItem value={4} primaryText="ВТБ" />
				    		</SelectField>
			    		] :
			    		this.state.dialogType == 1 ?
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
			    			</div> :
			    			this.state.dialogType == 2 ?
			    				`Вы уверены что хотите сбросить список "${ this.state.selectedIndex == 1 ? "НЕ ИНТЕРЕСНО" : this.state.selectedIndex == 3 && "ПЕРЕЗВОНИТЬ" }"` :
			    				this.state.dialogType == 3 &&
			    				"Вы уверены что хотите удалить компанию из базы?"
        	}
        </Dialog>
        <Dialog
        	title = {
        		<div>
        			<span>Последний вызов</span>
        			<div style = {{float: "right", margin: "-15px"}}>
	        			<RaisedButton 
	        				label = "звонить дальше"
	        				style = {{
	        					marginRight: "15px"
	        				}}
	        				primary
	        				onClick = {this.nextCall}
	        				disabled = {this.props.state.activeCompany && ([43,39,34,33].indexOf(this.props.state.activeCompany.call_internal_type_id) > -1 || [43,39,34,33].indexOf(this.props.state.activeCompany.call_destination_type_id) > -1) ? true : false}
	      				/>
	        			<IconButton>
	        				<NavigationClose onClick = {this.closeWorkDialog}/>
	        			</IconButton>
      				</div>
        		</div>
        	}
        	modal = {false}
        	open = {(!this.state.dialog && this.state.workDialog) || false}
        	onRequestClose = {this.closeWorkDialog}
        	autoScrollBodyContent={true}
        	actions = {this.props.state.activeCompany && Object.keys(this.props.state.activeCompany).length > 0 && [
        		<IconButton 
        			tooltip = "звонок" 
        			tooltipPosition = "top-center"
        			disabled = {
        				this.props.state.activeCompany &&
        				(
        					([38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(this.props.state.activeCompany.call_internal_type_id) > -1 ||
        					[38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(this.props.state.activeCompany.call_destination_type_id) > -1) &&
        					[15,16,17,24,25,26,27,28,29,30,31,32].indexOf(this.props.state.activeCompany.type_id) == -1
      					) ?
      					false :
      					true
        			}
        			onClick = {this.call.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id)}
      			>
        			{
        				this.props.state.activeCompany && (
        				(
        					[38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(this.props.state.activeCompany.call_internal_type_id) > -1 ||
        					[38,40,41,42,46,47,48,49,50,51,52,53,null].indexOf(this.props.state.activeCompany.call_destination_type_id) > -1
      					) ?
        				<DialerSip color="#00BFA5"/> :
        				this.props.state.activeCompany.call_destination_type_id == 34 ?
        				<PhoneForwarded color="#00BFA5"/> :
        				(
        					this.props.state.activeCompany.call_internal_type_id == 39 ||
        					this.props.state.activeCompany.call_destination_type_id == 39
        				) ?
        				<PhoneInTalk color="#00BFA5"/> :
        				(
        					[33,43,34].indexOf(this.props.state.activeCompany.call_internal_type_id) > -1 ||
        					[33,43].indexOf(this.props.state.activeCompany.call_destination_type_id) > -1
        				) &&
        				<SettingsPhone color="#00BFA5"/>
        				)
        			}
        		</IconButton>,
        		<IconButton 
        			tooltip = "сбросить статус звонка" 
        			tooltipPosition = "top-center" 
        			disabled = {
        				this.props.state.activeCompany &&
        				(
        					([34,39,33,43].indexOf(this.props.state.activeCompany.call_destination_type_id) > -1 ||
        					[34,39,33,43].indexOf(this.props.state.activeCompany.call_internal_type_id) > -1) &&
        					[15,16,17,24,25,26,27,28,29,30,31,32].indexOf(this.props.state.activeCompany.type_id) == -1
        				) ?
        				false : 
        				true
        			}
        			onClick = {this.resetCall.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id)}
      			>
        			<Replay color="#bd38c1"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = "оформить заявку" 
        			tooltipPosition = "top-center"
        			onClick = {this.companyCheck.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id, this.props.state.activeCompany && this.props.state.activeCompany.company_organization_name, 0)}
        			disabled = {(this.props.state.activeCompany && [15,16,17,24,25,26,27,28,29,30,31,32].indexOf(this.props.state.activeCompany.type_id) > -1) ? true : false}
      			>
        			<Check color="#a4c639"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = "перезвонить позднее" 
        			tooltipPosition = "top-center"
        			onClick = {this.companyCheck.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id, this.props.state.activeCompany && this.props.state.activeCompany.company_organization_name, 1)}
        			disabled = {[15,16,17,24,25,26,27,28,29,30,31,32,23].indexOf(this.props.state.activeCompany.type_id) > -1 ? true : false}
      			>
        			<Phone color="#EF6C00"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = {
        				this.props.state.activeCompany &&
        				this.props.state.activeCompany.type_id == 35 ?
        					"недозвон (в общий список)" :
        					"недозвон (в конец рабочего списка)"
        			} 
        			tooltipPosition = "top-center"
        			onClick = {this.changeType.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id, this.props.state.activeCompany && this.props.state.activeCompany.type_id == 35 ? 36 : 35)}
        			disabled = {[15,16,17,24,25,26,27,28,29,30,31,32].indexOf(this.props.state.activeCompany.type_id) > -1 ? true : false}
      			>
        			{
        				this.props.state.activeCompany &&
        				this.props.state.activeCompany.type_id == 35 ?
        					<CallEnd color="#C51162"/> :
        					<History color="#283593"/>
        			}
        		</IconButton>,
        		<IconButton 
        			tooltip = "не подходит" 
        			tooltipPosition = "top-center"
        			onClick = {this.changeType.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id, 14)}
        			disabled = {[15,16,17,24,25,26,27,28,29,30,31,32,14].indexOf(this.props.state.activeCompany.type_id) > -1 ? true : false}
      			>
        			<DeleteForever color="#E53935"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = "трудный клиент" 
        			tooltipPosition = "top-center"
        			onClick = {this.changeType.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id, 37)}
        			disabled = {[15,16,17,24,25,26,27,28,29,30,31,32,37].indexOf(this.props.state.activeCompany.type_id) > -1 ? true : false}
      			>
        			<SadFace color="#607D8B"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = "прослушать запись" 
        			tooltipPosition = "top-center"
        			disabled = {
        				this.props.state.activeCompany &&
        				this.props.state.activeCompany.file_name ?
        					false :
        					true
        			}
        			onClick={this.openURL.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.file_name)}
      			>
        			<Audiotrack color="#9575CD"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = "удалить из базы" 
        			tooltipPosition = "top-center"
        			onClick = {this.deleteCompanyDialog.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id)}
      			>
        			<RemoveCircle color="#9a2c2c"/>
        		</IconButton>
        	]}
				>
					{
						this.props.state.activeCompany && Object.keys(this.props.state.activeCompany).length > 0 ? [ 
							<div key = {20} style = {{margin: "20px 0", padding: "0 10px"}}>Список: {
        				this.props.state.activeCompany ? ( 
        				[9,35].indexOf(this.props.state.activeCompany.type_id) > -1 ? 
        					"В работе" :
        				this.props.state.activeCompany.type_id == 14 ?
        					"Не интересно" :
        					[15,16,17,24,25,26,27,28,29,30,31,32].indexOf(this.props.state.activeCompany.type_id) > -1 ?
        					"Утверждено" :
      						this.props.state.activeCompany.type_id == 23 ?
      							"Перезвонить" :
      							this.props.state.activeCompany.type_id == 36 ?
      								"Нет связи" :
      								this.props.state.activeCompany.type_id == 37 &&
      								"Сложные") : "–"
        			}</div>,
							<Divider key = {19}/>,
							<div key = {0} style = {{margin: "20px 0", padding: "0 10px"}}>Ф.И.О: {this.props.state.activeCompany && [this.props.state.activeCompany.company_person_name, this.props.state.activeCompany.company_person_surname, this.props.state.activeCompany.company_person_patronymic].join(" ")}</div>,
							<Divider key = {1}/>,
							<div key = {2} style = {{margin: "20px 0", padding: "0 10px"}}>Компания: {this.props.state.activeCompany && this.props.state.activeCompany.company_organization_name}</div>,
							<Divider key = {3}/>,
							<div key = {4} style = {{margin: "20px 0", padding: "0 10px"}}>Регион: {this.props.state.activeCompany && this.props.state.activeCompany.region_name}</div>,
							<Divider key = {5}/>,
							<div key = {6} style = {{margin: "20px 0", padding: "0 10px"}}>Город: {this.props.state.activeCompany && this.props.state.activeCompany.city_name}</div>,
							<Divider key = {7}/>,
							<div key = {8} style = {{margin: "20px 0", padding: "0 10px"}}>Телефон: {this.props.state.activeCompany && this.props.state.activeCompany.company_phone}</div>,
							<Divider key = {9}/>,
							<div key = {10} style = {{margin: "20px 0", padding: "0 10px"}}>ИНН: {this.props.state.activeCompany && this.props.state.activeCompany.company_inn}</div>,
							<Divider key = {11} />,
							<div key = {12} style = {{margin: "20px 0", padding: "0 10px"}}>Тип компании: {this.props.state.activeCompany && this.props.state.activeCompany.template_type_id == 11 ? "ИП" : "ООО"}</div>,
							<Divider key = {13} />,
							<div key = {14} style = {{margin: "20px 0", padding: "0 10px"}}>Статус обработки: {
								[15,16,17,24,25,26,27,28,29,30,31,32].indexOf(this.props.state.activeCompany.type_id) > -1 ?
									(this.props.state.activeCompany.type_id == 15 ? "В процессе" :
									this.props.state.activeCompany.type_id == 16 ? "Успешно" :
									this.props.state.activeCompany.type_id == 17 ? "Ошибка" :
									this.props.state.activeCompany.type_id == 24 ? "Дубликат" :
									this.props.state.activeCompany.type_id == 25 ? "Сбор документов" :
									this.props.state.activeCompany.type_id == 26 ? "Обработка комплекта" :
									this.props.state.activeCompany.type_id == 27 ? "Назначение встречи" :
									this.props.state.activeCompany.type_id == 28 ? "Встреча назначена" :
									this.props.state.activeCompany.type_id == 29 ? "Постобработка" :
									this.props.state.activeCompany.type_id == 30 ? "Счет открыт" :
									this.props.state.activeCompany.type_id == 31 ? "Отказ Банка" :
									this.props.state.activeCompany.type_id == 32 && "Отказ клиента") :
									"–"
							}</div>,							
							<Divider key = {17} />,
							<div key = {18} style = {{margin: "20px 0", padding: "0 10px"}}>Дата перезвона: {this.props.state.activeCompany && this.props.state.activeCompany.company_date_call_back || "–"}</div>,
							<Divider key = {15} />,
							<div key = {16} style = {{margin: "20px 0", padding: "0 10px"}}>Коментарий: {this.props.state.activeCompany && this.props.state.activeCompany.company_comment || "–"}</div>,
						] : "Не удалось найти последний не распределенный вызов"
					}
					<br/>
        </Dialog>
			</Paper>
		</div> ||
		<Redirect to = {this.state.hash} />
	}
}