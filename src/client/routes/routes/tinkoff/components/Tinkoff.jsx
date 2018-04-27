import React from 'react';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';
import Restore from 'material-ui/svg-icons/action/restore';
import Favorite from 'material-ui/svg-icons/action/favorite';
import HighlightOff from 'material-ui/svg-icons/action/highlight-off';
import Check from 'material-ui/svg-icons/navigation/check';
import DeleteForever from 'material-ui/svg-icons/action/delete-forever';
import CheckCircle from 'material-ui/svg-icons/action/check-circle';
import Phone from 'material-ui/svg-icons/communication/phone';
import Paper from 'material-ui/Paper';
import RaisedButton from 'material-ui/RaisedButton';
import IconButton from 'material-ui/IconButton';
import FlatButton from 'material-ui/FlatButton';
import { Redirect } from 'react-router';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import DatePicker from 'material-ui/DatePicker';
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
		this.state = {
			selectedIndex: 0,
			limit: 10,
			hash: localStorage.getItem("hash")
		};
		this.refresh = this.refresh.bind(this);
		this.setDistributionFilter = this.setDistributionFilter.bind(this);
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
	sendToApi(company_id){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "sendToApi",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify([company_id])
				]
			}
		});
	}
	changeType(company_id, type_id){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "setCompanyType",
				priority: true,
				values: [
					this.props.state.connectionHash,
					company_id,
					type_id
				]
			}
		});
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
	render(){
		localStorage.removeItem("hash");
		console.log(this.props.state.distribution);
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
            label={"УТВЕРЖДЕНО ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 15 || i.type_id == 16 || i.type_id == 17).length || 0)+")"}
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
	              <TableHeaderColumn colSpan="8">
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
		              	(this.state.selectedIndex == 2 && (company.type_id == 15 || company.type_id == 16 || company.type_id == 17)) ||
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
		                	<TableRowColumn>
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 1 || this.state.selectedIndex == 3) &&
				                	<IconButton
				                		title="Оформить заявку"
				                		onClick = {this.sendToApi.bind(this, company.company_id)}
				                	>
				                		<Check color = "#a4c639"/>
				                	</IconButton>
		                		}
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 1) && 
		                			<IconButton
		                				title="Перезвонить"
				                		onClick = {this.changeType.bind(this, company.company_id, 23)}
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
		                				color: company.type_id == 15 ? "inherit" : company.type_id == 16 ? "green" : company.type_id == 17 && "red"
		                			}}>
		                				{
				                			company.type_id == 15 ? "В процессе" :
				                			company.type_id == 16 ? "Успешно" :
				                			company.type_id == 17 && "Ошибка"
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
			</Paper>
		</div> ||
		<Redirect to = {this.state.hash} />
	}
}