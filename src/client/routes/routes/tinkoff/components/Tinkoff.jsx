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
import Create from 'material-ui/svg-icons/content/create';
import PhoneForwarded from 'material-ui/svg-icons/notification/phone-forwarded';
import PhoneInTalk from 'material-ui/svg-icons/notification/phone-in-talk';
import Block from 'material-ui/svg-icons/content/block';
import RemoveCircle from 'material-ui/svg-icons/content/remove-circle';
import SettingsPhone from 'material-ui/svg-icons/action/settings-phone';
import ArrowTop from 'material-ui/svg-icons/hardware/keyboard-arrow-up';
import ArrowDown from 'material-ui/svg-icons/hardware/keyboard-arrow-down';
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
import AutoComplete from 'material-ui/AutoComplete';
import Chip from 'material-ui/Chip';
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
	"difficult",
	"duplicates"
];
const categoriesTypes = [
	[35,9],
	[14],
	[13],
	[23],
	[36],
	[37],
	[24]
];
export default class Tinkoff extends React.Component {
	constructor(props){
		super(props);
		const date = new Date();
		this.state = {
			selectedIndex: 0,
			limit: 10,
			hash: localStorage.getItem("hash"),
			dialog: false,
			comment: "",
			company: {},
			dialogType: 1,
			dateCallBack: new Date(),
			timeCallBack: new Date(),
			selectedBanks: [],
			workDialog: false,
			searchFilialsValues: [],
			addInfo: false
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
		this.searchFilialChange = this.searchFilialChange.bind(this);
		this.editPhone = this.editPhone.bind(this);
		this.confirmEditInformation = this.confirmEditInformation.bind(this);
		this.searchCityChange = this.searchCityChange.bind(this);
		this.addInfo = this.addInfo.bind(this);
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
		let banks = this.state.selectedBanks.map(selectedBank => {
			let searchFilialValue = this.state.searchFilialsValues.find(searchFilial => searchFilial.bank_id == selectedBank.bank_id);
			return {
				bank_id: selectedBank.bank_id,
				bank_filial_id: searchFilialValue ? searchFilialValue.filial_id : 0
			}
		});
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "sendToApi",
				priority: true,
				values: [
					this.props.state.connectionHash,
					this.state.company.company_id,
					this.state.comment,
					JSON.stringify(banks)
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
	companyCheck(company, dialogType){
		if (dialogType == 1){
			const date = new Date();
			this.setState({
				dateCallBack: date,
				timeCallBack: date
			});
		}
		this.setState({
			company,
			comment: company.company_comment || "",
			dialog: true,
			dialogType,
			city: company.city_name,
			phone: company.company_phone
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
			company: {},
			selectedBanks: [],
			searchFilialsValues: [],
			city: "",
			phone: ""
		});
		this.props.dispatch({
			type: "merge",
			data: {
				banksFilials: {}
			}
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
	chipClick(bank_id){
		let selectedBanks = this.state.selectedBanks,
				searchFilialsValues = this.state.searchFilialsValues,
				newSelectedBanks = selectedBanks.filter(selectedBank => selectedBank.bank_id != bank_id),
				newSearchFilialsValues = searchFilialsValues.filter(searchFilialValue => searchFilialValue.bank_id != bank_id);
		this.setState({
			selectedBanks: newSelectedBanks,
			searchFilialsValues: newSearchFilialsValues
		});
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
		this.setState({
			addInfo: false
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
			workDialog: !bool || typeof bool == "object" ? false : true,
			addInfo: false
		});
	}
	bankSelect(event, key, payload){
		let selectedBanks = this.state.selectedBanks;
		selectedBanks.push(this.state.company.company_banks["b"+payload]);
		this.setState({
			selectedBanks
		});
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "getBankCityFilials",
				values: [
					this.props.state.connectionHash,
					payload,
					this.state.company.city_id
				]
			}
		});
	}
	searchFilialChange(bank_id, search_text){
		let searchFilialsValues = this.state.searchFilialsValues,
				banksFilials = this.props.state.banksFilials,
				searchKey = Object.keys(searchFilialsValues).find(i => searchFilialsValues[i].bank_id == bank_id),
				searchObject = searchFilialsValues[searchKey],
				bankFilials = banksFilials[Object.keys(banksFilials).find(bankFilialKey => banksFilials[bankFilialKey].bank_id == bank_id)].bank_filials,
				searchFilial = bankFilials.find(bankFilial => bankFilial.bank_filial_name.toLowerCase() == search_text.toLowerCase()),
				filial_id = searchFilial && searchFilial.bank_filial_id;
		if (searchObject) {
			searchObject.search_text = search_text;
			Object.assign(searchObject, {
				search_text,
				filial_id
			});
			searchFilialsValues[searchKey] = searchObject;
		} else {
			searchObject = {
				bank_id,
				search_text,
				filial_id
			};
			searchFilialsValues.push(searchObject);
		}
		this.setState({
			searchFilialsValues
		});
	}
	editPhone(obj, phone){
		this.setState({
			phone
		});
	}
	searchCityChange(city){
		this.setState({
			city
		});
	}
	confirmEditInformation(){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "editCompanyInformation",
				values: [
					this.props.state.connectionHash,
					this.state.company.company_id,
					this.state.phone,
					this.props.state.cities.find(city => city.city_name.toLowerCase() == this.state.city.toLowerCase()).city_id
				]
			}
		});
		this.closeDialog();
	}
	addInfo(){
		this.setState({
			addInfo: !this.state.addInfo
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
          <BottomNavigationItem
            label={"ДУБЛИКАТЫ"}
            icon={<Block/>}
            onClick={() => this.select(6)}
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
	              <TableHeaderColumn colSpan={this.state.selectedIndex == 3 ? "10" : this.state.selectedIndex == 2 ? "11" : "9"}>
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
		              			[1,2,3,4,5,6].indexOf(this.state.selectedIndex) != -1 &&
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
				                	disabled = {true}
		              			/>
		              		}
		              	</div>
	              	</div>
	              </TableHeaderColumn>
	            </TableRow>
	            <TableRow>
	            	<TableHeaderColumn colSpan={this.state.selectedIndex == 3 ? "10" : this.state.selectedIndex == 2 ? "11" : "9"} style = {{textAlign: "right"}}>
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
	            					this.state.selectedIndex == 2 ? [13] :
	            					this.state.selectedIndex == 3 ? [23] :
	            					this.state.selectedIndex == 4 ? [36] :
	            					this.state.selectedIndex == 5 ? [37] :
	            					this.state.selectedIndex == 6 && [24]
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
	              <TableHeaderColumn>Банки</TableHeaderColumn>
	              {
	              	this.state.selectedIndex == 2 &&
	              	<TableHeaderColumn>Коментарий</TableHeaderColumn>
	              }
	              {
	              	this.state.selectedIndex == 3 && 
	              	<TableHeaderColumn>Дата и Время</TableHeaderColumn>
	              }
              	<TableHeaderColumn>{[2,6].indexOf(this.state.selectedIndex) == -1 ? "Действия" : "Статус обработки"}</TableHeaderColumn>
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
		              	(this.state.selectedIndex == 2 && company.type_id == 13) ||
		              	(this.state.selectedIndex == 3 && company.type_id == 23) ||
		              	(this.state.selectedIndex == 4 && company.type_id == 36) ||
		              	(this.state.selectedIndex == 5 && company.type_id == 37) ||
		              	(this.state.selectedIndex == 6 && company.type_id == 24) 
		              ) &&
		              <TableRow key = {key} style = {{background: [33,34,43,38,39].indexOf(company.call_type) > -1 ? "#E8F5E9" : (company.type_id == 9 && company.old_type_id == 23) ? "#ffe1c7" : "inherit"}}>
		                <TableRowColumn>{company.company_phone || "–"}</TableRowColumn>
		                <TableRowColumn>{company.template_type_id == 11 ? "ИП" : "ООО"}</TableRowColumn>
		                <TableRowColumn>{company.company_inn || "–"}</TableRowColumn>
		                <TableRowColumn>{company.region_name || "–"}</TableRowColumn>
		                <TableRowColumn>{company.city_name || "–"}</TableRowColumn>
		                <TableRowColumn style={{whiteSpace: "normal"}}>{company.company_organization_name || "–"}</TableRowColumn>
		                <TableRowColumn style={{whiteSpace: "normal"}}>{`${company.company_person_name} ${company.company_person_surname} ${company.company_person_patronymic}`.split("null").join("")}</TableRowColumn>
		                <TableRowColumn style={{whiteSpace: "normal"}}>{Object.keys(company.company_banks).filter(i => company.company_banks[i].bank_suits != 0).map(i => company.company_banks[i].bank_name).join(" ")}</TableRowColumn>
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
				                		onClick = {this.companyCheck.bind(this, company, 0)}
				                	>
				                		<Check color = "#a4c639"/>
				                	</IconButton>
		                		}
		                		{
		                			[0,1,4,5].indexOf(this.state.selectedIndex) > -1 && 
		                			<IconButton
		                				title="Перезвонить"
				                		onClick = {this.companyCheck.bind(this, company, 1)}
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
		                			[2,6].indexOf(this.state.selectedIndex) > -1 &&
		                			<span style = {{
		                				whiteSpace: "pre"
		                			}}>
		                				{
		                					Object.keys(company.company_banks).map((i, key) => <div
		                						style = {{
		                							color: company.company_banks[i].type_id == 15 ? "inherit" : company.company_banks[i].type_id == 16 ? "green" : company.company_banks[i].type_id == 17 && "red"
		                						}}
		                						key = {key}
		                					>
		                						{`${company.company_banks[i].bank_name}: ${company.company_banks[i].company_bank_status || "–"}`}
	                						</div>)
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
					              {
		                			[0,1,3,4,5].indexOf(this.state.selectedIndex) > -1 &&
			                		<IconButton
					                	title = "Редактировать компанию"
					                	onClick = {this.companyCheck.bind(this, company, 4)}
					                >
					                	<Create color = "#da66da"/>
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
	          				colSpan = "9"
	          				style = {{
	          					textAlign: "center"
	          				}}
	          			>
	          				Нет загруженых записей
	          			</TableRowColumn>
	          		</TableRow>
	          	}
	          	<TableRow>
	            	<TableHeaderColumn colSpan={this.state.selectedIndex == 3 ? "10" : this.state.selectedIndex == 2 ? "11" : "9"} style = {{textAlign: "right"}}>
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
	            					this.state.selectedIndex == 2 ? [13] :
	            					this.state.selectedIndex == 3 ? [23] :
	            					this.state.selectedIndex == 4 ? [36] :
	            					this.state.selectedIndex == 5 ? [37] :
	            					this.state.selectedIndex == 6 && [24]
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
          		`Оформление заявки – ${this.state.company && this.state.company.company_organization_name}` : 
          		this.state.dialogType == 1 ? 
          			`Выбор даты и времени – ${this.state.company && this.state.company.company_organization_name}` :
          			this.state.dialogType == 4 &&
          				`Редактирование информации – ${this.state.company && this.state.company.company_organization_name}`
          }
          actions={[
			      <FlatButton
			        label="Отменить"
			        secondary
			        onClick={this.closeDialog}
			      />,
			      <FlatButton
			        label= {this.state.dialogType == 2 ? "Сбросить" : this.state.dialogType == 3 ? "Удалить" : "Отправить"}
			        primary
			        disabled = {
			        	(
			        		this.state.dialogType == 0 ? 
				        		(
				        			this.state.selectedBanks.length == 0 || 
				        			(
				        				this.props.state.banksFilials && 
				        				Object.keys(this.props.state.banksFilials).length > 0 &&
				        				this.state.selectedBanks.filter(selectedBank => Object.keys(this.props.state.banksFilials).map(bankFilialKey => this.props.state.banksFilials[bankFilialKey]).find(bankFilial => bankFilial.bank_id == selectedBank.bank_id) && Object.keys(this.props.state.banksFilials).map(bankFilialKey => this.props.state.banksFilials[bankFilialKey]).find(bankFilial => bankFilial.bank_id == selectedBank.bank_id).bank_filials.length > 0).length !=
				        				this.state.searchFilialsValues.filter(searchFilialValue => Object.keys(this.props.state.banksFilials).map(bankFilialKey => this.props.state.banksFilials[bankFilialKey]).find(bankFilial => bankFilial.bank_id == searchFilialValue.bank_id) && Object.keys(this.props.state.banksFilials).map(bankFilialKey => this.props.state.banksFilials[bankFilialKey]).find(bankFilial => bankFilial.bank_id == searchFilialValue.bank_id).bank_filials.length > 0 && searchFilialValue.filial_id >= 0).length
			        				)
			        			) :
			        			this.state.dialogType == 4 &&
			        				(
			        					!this.props.state.cities ||
			        					this.props.state.cities.length == 0 ||
			        					!this.state.city ||
			        					this.props.state.cities.map(city => city.city_name.toLowerCase()).indexOf(this.state.city.toLowerCase()) == -1 ||
			        					!/\+7[0-9]{10}/.test(this.state.phone)
			        				)
	        			) ? true : false
		        	}
			        onClick={
			        	this.state.dialogType == 0 ? 
			        		this.sendToApi :
			        		this.state.dialogType == 1 ? 
			        			this.changeType.bind(this, this.state.company.company_id, 23, [this.state.dateCallBack, this.state.timeCallBack]) :
			        			this.state.dialogType == 2 ?
			        				this.reset.bind(this, this.state.selectedIndex == 1 ? 14 : 23) :
			        				this.state.dialogType == 3 ?
			        					this.deleteCompany.bind(this, this.state.companyID) :
			        					this.state.dialogType == 4 &&
			        						this.confirmEditInformation
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
						      value={this.state.comment || ""}
						      multiLine={true}
						      fullWidth={true}
						      rows={5}
						      rowsMax={10}
						     	onChange = {(event, text) => {
						     		this.comment(text)
						     	}}
						     	key = {0}
				    		/>,
				    		<div
				    			key = {1}
				    			style = {{
				    				display: "flex",
    								flexWrap: "wrap"
				    			}}
				    		>
				    			{
				    				this.state.selectedBanks && this.state.selectedBanks.map((i, key) => (
				    					<Chip 
					    					key = {key}
					    					style = {{
					    						margin: "4px"
					    					}}
					    					onRequestDelete={this.chipClick.bind(this, i.bank_id)}
				    					>
				    						{i.bank_name} 
			    						</Chip>
		    						))
				    			}
				    		</div>,
				    		<SelectField
				    			floatingLabelText="Выбор банка"
				    			errorText = {this.state.selectedBanks.length == 0 && "Необходимо выбрать банк"}
				    			onChange = {this.bankSelect}
				    			key = {2}
				    			disabled = {this.state.company.company_banks && Object.keys(this.state.company.company_banks).filter(companyBankKey => this.state.company.company_banks[companyBankKey].bank_suits != 0).length == this.state.selectedBanks.length}
				    		>
				    			{
				    				this.state.company && 
				    				this.state.company.company_banks && 
				    				Object.keys(this.state.company.company_banks).filter(i => this.state.company.company_banks[i].bank_suits != 0 && this.state.selectedBanks.map(selectedBank => selectedBank.bank_id).indexOf(this.state.company.company_banks[i].bank_id) == -1).map((i, key) => (
				    					<MenuItem 
				    						value={this.state.company.company_banks[i].bank_id} 
				    						primaryText={this.state.company.company_banks[i].bank_name} 
				    						key={key}
			    						/>
		    						))
				    			}
				    		</SelectField>,
				    		<div
				    			key = {3}
				    		>
				    			{
				    				this.state.company && 
				    				this.state.selectedBanks.length > 0 && 
				    				!!this.props.state.banksFilials && 
				    				Object.keys(this.props.state.banksFilials).length > 0 &&
				    				this.state.selectedBanks.filter(selectedBank => Object.keys(this.props.state.banksFilials).filter(bankFilialKey => this.props.state.banksFilials[bankFilialKey].bank_id == selectedBank.bank_id && this.props.state.banksFilials[bankFilialKey].bank_filials.length > 0)[0]).length > 0 &&
				    				Object.keys(this.props.state.banksFilials).filter((bankFilialsKey, key) => this.state.selectedBanks.map(selectedBank => selectedBank.bank_id).indexOf(this.props.state.banksFilials[bankFilialsKey].bank_id) > -1 && this.props.state.banksFilials[bankFilialsKey].bank_filials.length > 0).map((bankFilialsKey, key) => (
			    						<div key = {key}>
			    							{
									    		<AutoComplete
									          floatingLabelText = {`Филиал банка: ${Object.keys(this.state.company.company_banks).map(companyBankKey => this.state.company.company_banks[companyBankKey]).find(bank => bank.bank_id == this.props.state.banksFilials[bankFilialsKey].bank_id).bank_name}`}
									          searchText={this.state.searchFilialsValues.find(i => i.bank_id == this.props.state.banksFilials[bankFilialsKey].bank_id) && this.state.searchFilialsValues.find(i => i.bank_id == this.props.state.banksFilials[bankFilialsKey].bank_id).search_text}
									          onUpdateInput={this.searchFilialChange.bind(this, this.props.state.banksFilials[bankFilialsKey].bank_id)}
									          dataSource={this.props.state.banksFilials[bankFilialsKey].bank_filials.map(i => i.bank_filial_name) || []}
									          filter={(searchText, key) => (key.toLowerCase().indexOf(searchText && searchText.toLowerCase()) !== -1)}
									          openOnFocus={true}
									          fullWidth = {true}
									          menuStyle = {{
									          	overflowY: "scroll",
									          	maxHeight: "300px"
									          }}
									          menuProps = {{
									          	menuItemStyle: {
									          		whiteSpace: "normal",
									          		lineHeight: "20px",
									          		minHeight: "none",
									          		padding: "10px 0"
									          	}
									          }}
									          popoverProps = {{
									          	canAutoPosition: true
									          }}
									          listStyle = {{
									          	overflow: "auto"
									          }}
									          disableFocusRipple= {false}
									          errorText = {(this.state.searchFilialsValues.find(i => i.bank_id == this.props.state.banksFilials[bankFilialsKey].bank_id) && this.state.searchFilialsValues.find(i => i.bank_id == this.props.state.banksFilials[bankFilialsKey].bank_id).filial_id >= 0) ? "" : "Необходимо выбрать филиал из списка" }
									        />
			    							}
			    						</div>
			    					))
				    			}
				    		</div>
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
							      format = '24hr'
							    />
							    <div style = {{fontSize: "12px"}}>
							    		<Info style={{verticalAlign: "middle", width: "25px", color: "#e8a521"}}/> Время и дата не должны быть меньше текущих даты и времени
							    </div>
			    			</div> :
			    			this.state.dialogType == 2 ?
			    				`Вы уверены что хотите сбросить список "${ this.state.selectedIndex == 1 ? "НЕ ИНТЕРЕСНО" : this.state.selectedIndex == 3 && "ПЕРЕЗВОНИТЬ" }"` :
			    				this.state.dialogType == 3 ?
			    					"Вы уверены что хотите удалить компанию из базы?" :
			    					this.state.dialogType == 4 &&
			    						[
			    							<TextField
			    								floatingLabelText = "Телефон"
			    								floatingLabelFixed = {true}
			    								errorText = {/\+7[0-9]{10}/.test(this.state.phone) ? "" : "Номер должен быть вида +7**********"}
			    								value = {this.state.phone || ""}
			    								onChange = {this.editPhone}
			    								fullWidth = {true}
			    								key = {0}
			    							/>,
			    							<AutoComplete
								          floatingLabelText = "Город"
								          searchText={this.state.city}
								          onUpdateInput={this.searchCityChange}
								          dataSource={this.props.state.cities && this.props.state.cities.map(city => city.city_name) || []}
								          filter={(searchText, key) => (key.toLowerCase().indexOf(searchText && searchText.toLowerCase()) !== -1)}
								          openOnFocus={true}
								          menuStyle = {{
								          	overflowY: "scroll",
								          	maxHeight: "300px"
								          }}
								          menuProps = {{
								          	menuItemStyle: {
								          		whiteSpace: "normal",
								          		lineHeight: "20px",
								          		minHeight: "none",
								          		padding: "10px 0"
								          	}
								          }}
								          popoverProps = {{
								          	canAutoPosition: true
								          }}
								          listStyle = {{
								          	overflow: "auto"
								          }}
								          floatingLabelFixed = {true}
								          disableFocusRipple= {false}
								          errorText = {this.props.state.cities && this.state.city && this.props.state.cities.map(city => city.city_name.toLowerCase()).indexOf(this.state.city.toLowerCase()) == -1 ? "Необходимо выбрать город из списка" : ""}
								          key = {1}
								          fullWidth = {true}
								        />,
								        <div
								        	key = {2}
								        >
								        	{
								        		this.props.state.cities && 
								        		this.props.state.cities.length > 0 && 
								        		this.state.city &&
								        		this.props.state.cities.map(city => city.city_name.toLowerCase()).indexOf(this.state.city.toLowerCase()) > -1 &&
								        		`Для города подходят банки: ${this.props.state.cities.find(city => city.city_name.toLowerCase() == this.state.city.toLowerCase()).city_banks.map(bank => bank.bank_name).join(" ") || "–"}`
								        	}
								        </div>
			    						]
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
	        				disabled = {this.props.state.activeCompany && ([43,39,34].indexOf(this.props.state.activeCompany.call_internal_type_id) > -1 || [43,39,34,33].indexOf(this.props.state.activeCompany.call_destination_type_id) > -1) ? true : false}
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
        					this.props.state.activeCompany.type_id != 13
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
        					this.props.state.activeCompany.type_id != 13
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
        			onClick = {this.companyCheck.bind(this, this.props.state.activeCompany, 0)}
        			disabled = {(this.props.state.activeCompany && this.props.state.activeCompany.type_id == 13) ? true : false}
      			>
        			<Check color="#a4c639"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = "перезвонить позднее" 
        			tooltipPosition = "top-center"
        			onClick = {this.companyCheck.bind(this, this.props.state.activeCompany, 1)}
        			disabled = {this.props.state.activeCompany.type_id == 13 ? true : false}
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
        			disabled = {this.props.state.activeCompany.type_id == 13 ? true : false}
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
        			disabled = {this.props.state.activeCompany.type_id == 13 ? true : false}
      			>
        			<DeleteForever color="#E53935"/>
        		</IconButton>,
        		<IconButton 
        			tooltip = "трудный клиент" 
        			tooltipPosition = "top-center"
        			onClick = {this.changeType.bind(this, this.props.state.activeCompany && this.props.state.activeCompany.company_id, 37)}
        			disabled = {this.props.state.activeCompany.type_id == 13 ? true : false}
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
        		</IconButton>,
        		<IconButton 
        			tooltip = "Редактировать информацию" 
        			tooltipPosition = "top-center"
        			onClick = {this.companyCheck.bind(this, this.props.state.activeCompany, 4)}
        			disabled = {
        				this.props.state.activeCompany &&
        				this.props.state.activeCompany.type_id == 13 ?
        					true :
        					false
        			}
      			>
        			<Create color="#da66da"/>
        		</IconButton>
        	]}
				>
					{
						this.props.state.activeCompany && Object.keys(this.props.state.activeCompany).length > 0 ? [ 
							<div key = {0} style = {{margin: "20px 0", padding: "0 10px"}}>Ф.И.О: {this.props.state.activeCompany && [this.props.state.activeCompany.company_person_name, this.props.state.activeCompany.company_person_surname, this.props.state.activeCompany.company_person_patronymic].join(" ")}</div>,
							<Divider key = {1}/>,
							<div key = {2} style = {{margin: "20px 0", padding: "0 10px"}}>Город: {this.props.state.activeCompany && this.props.state.activeCompany.city_name}</div>,
							<Divider key = {3}/>,
							<div key = {4} style = {{margin: "20px 0", padding: "0 10px"}}>Тип компании: {this.props.state.activeCompany && this.props.state.activeCompany.template_type_id == 11 ? "ИП" : "ООО"}</div>,
							<Divider key = {5}/>,
							<div key = {6} style = {{margin: "20px 0", padding: "0 10px"}}>Подходит для банков: {this.props.state.activeCompany && Object.keys(this.props.state.activeCompany.company_banks).map(i => this.props.state.activeCompany.company_banks[i].bank_name).join(" ")}</div>,
							<Divider key = {7}/>,
        			this.state.addInfo ? <div 
        				key = {8}
        			>
        				<div 
        					style = {{
        						margin: "20px 0", 
        						padding: "0 10px"
      						}}
    						>
    							Список: {
		        				this.props.state.activeCompany ? ( 
		        				[9,35].indexOf(this.props.state.activeCompany.type_id) > -1 ? 
		        					"В работе" :
		        				this.props.state.activeCompany.type_id == 14 ?
		        					"Не интересно" :
		        					this.props.state.activeCompany.type_id == 13 ?
		        					"Утверждено" :
		      						this.props.state.activeCompany.type_id == 23 ?
		      							"Перезвонить" :
		      							this.props.state.activeCompany.type_id == 36 ?
		      								"Нет связи" :
		      								this.props.state.activeCompany.type_id == 37 ?
		      								"Сложные" :
		      									this.props.state.activeCompany.type_id == 24 &&
		      									"Дубликаты") : "–"
        					}
      					</div>
      					<Divider/>
      					<div style = {{margin: "20px 0", padding: "0 10px"}}>Компания: {this.props.state.activeCompany && this.props.state.activeCompany.company_organization_name}</div>
      					<Divider/>
      					<div style = {{margin: "20px 0", padding: "0 10px"}}>Регион: {this.props.state.activeCompany && this.props.state.activeCompany.region_name}</div>
      					<Divider/>
      					<div style = {{margin: "20px 0", padding: "0 10px"}}>Телефон: {this.props.state.activeCompany && this.props.state.activeCompany.company_phone}</div>
      					<Divider/>
      					<div style = {{margin: "20px 0", padding: "0 10px"}}>ИНН: {this.props.state.activeCompany && this.props.state.activeCompany.company_inn}</div>
      					<Divider/>
      					<div style = {{margin: "20px 0", padding: "0 10px"}}>
      						Статусы обработки: {
										this.props.state.activeCompany && Object.keys(this.props.state.activeCompany.company_banks).map(key => this.props.state.activeCompany.company_banks[key]).map((bank, key) => (<div style = {{margin: "5px 0", color: (bank.type_id == 15 || !bank.type_id) ? "inherit" : bank.type_id == 16 ? "green" : "red"}} key = {key}>{`${bank.bank_name}: ${bank.company_bank_status || "–"}`}</div>))
									}
								</div>
								<Divider/>
								<div style = {{margin: "20px 0", padding: "0 10px"}}>Дата перезвона: {this.props.state.activeCompany && this.props.state.activeCompany.company_date_call_back || "–"}</div>
								<Divider/>
								<div style = {{margin: "20px 0", padding: "0 10px"}}>Коментарий: {this.props.state.activeCompany && this.props.state.activeCompany.company_comment || "–"}</div>
								<Divider/>
        			</div> : "",
        			<FlatButton
        				label = "дополнительно"
        				key = {9}
        				onClick = {this.addInfo}
        				style = {{
        					marginTop: "10px",
        					float: "right"
        				}}
        				labelPosition = "after"
        				icon = {this.state.addInfo ? <ArrowTop/> : <ArrowDown/>}
        			/>
						] : "Не удалось найти последний не распределенный вызов"
					}
					<br/>
        </Dialog>
			</Paper>
		</div> ||
		<Redirect to = {this.state.hash} />
	}
}