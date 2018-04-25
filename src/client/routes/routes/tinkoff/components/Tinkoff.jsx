import React from 'react';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';
import Restore from 'material-ui/svg-icons/action/restore';
import Favorite from 'material-ui/svg-icons/action/favorite';
import HighlightOff from 'material-ui/svg-icons/action/highlight-off';
import Check from 'material-ui/svg-icons/navigation/check';
import DeleteForever from 'material-ui/svg-icons/action/delete-forever';
import CheckCircle from 'material-ui/svg-icons/action/check-circle';
import Paper from 'material-ui/Paper';
import RaisedButton from 'material-ui/RaisedButton';
import { Redirect } from 'react-router';
import {
  Table,
  TableBody,
  TableFooter,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn,
} from 'material-ui/Table';
export default class Tinkoff extends React.Component {
	constructor(props){
		super(props);
		this.state = {
			selectedIndex: 0,
			limit: 10,
			hash: localStorage.getItem("hash")
		};
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
	upload(){
		let uploadCompanies = this.props.state.companies.filter(item => item.type_id == 13).map(i => i.company_id);
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "sendToApi",
				priority: true,
				values: [
					this.props.state.connectionHash,
					JSON.stringify(uploadCompanies)
				]
			}
		});
	}
	valid(company_id, valid){
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "companyValidation",
				priority: true,
				values: [
					this.props.state.connectionHash,
					company_id,
					valid
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
		return (this.state.hash == "/" || this.state.hash == "/tinkoff" || !this.state.hash) && <div>
			<Paper zDepth={0}>
				<BottomNavigation selectedIndex={this.state.selectedIndex}>
					<BottomNavigationItem
            label={"В РАБОТЕ ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 10 || i.type_id == 9).length || 0)+")"}
            icon={<Restore/>}
            onClick={() => this.select(0)}
          />
          <BottomNavigationItem
            label={"ИНТЕРЕСНО ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 13).length || 0)+")"}
            icon={<Favorite/>}
            onClick={() => this.select(1)}
          />
          <BottomNavigationItem
            label={"НЕ ИНТЕРЕСНО ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 14).length || 0)+")"}
            icon={<HighlightOff/>}
            onClick={() => this.select(2)}
          />
          <BottomNavigationItem
            label={"УТВЕРЖДЕНО ("+(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 15 || i.type_id == 16 || i.type_id == 17).length || 0)+")"}
            icon={<CheckCircle/>}
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
		              		lineHeight: "36px",
		              		fontWeight: "bold",
		              		fontSize: "14px",
		              		color: this.props.state.messageType == "success" ? "#789a0a" : this.props.state.messageType == "error" ? "#ff4081" : "inherit"
		              	}}>
		              		{ this.props.state.message }
		              	</span>
		              	<div style = {{float: "right"}}>
			              	{
			              		this.state.selectedIndex == 0 &&
				                <RaisedButton 
				                	label = "Обновить список"
				                	backgroundColor="#a4c639"
				                	labelColor = "#fff"
				                	onClick = {()=>{this.refresh.call(this)}}
				                	disabled = {(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 9 || i.type_id == 10).length >= this.state.limit) ? true : false}
				                />
				              }
				              {
				              	this.state.selectedIndex == 1 &&
				                <RaisedButton 
				                	label = "Утвердить список интересных компаний"
				                	backgroundColor="#FF5722"
				                	labelColor = "#fff"
				                	onClick = {()=>{this.upload.call(this)}}
				                	disabled = {(this.props.state.companies && this.props.state.companies.filter(i => i.type_id == 13).length > 0) ? false : true}
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
              	<TableHeaderColumn>{this.state.selectedIndex != 3 ? "Действия" : "Статус обработки"}</TableHeaderColumn>
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
		              	(this.state.selectedIndex == 1 && company.type_id == 13) || 
		              	(this.state.selectedIndex == 2 && company.type_id == 14) || 
		              	(this.state.selectedIndex == 3 && (company.type_id == 15 || company.type_id == 16 || company.type_id == 17))
		              ) &&
		              <TableRow key = {key}>
		                <TableRowColumn>{company.company_phone || "–"}</TableRowColumn>
		                <TableRowColumn>{company.template_id == 1 ? "ИП" : "ООО"}</TableRowColumn>
		                <TableRowColumn>{company.company_inn || "–"}</TableRowColumn>
		                <TableRowColumn>{company.region_name || "–"}</TableRowColumn>
		                <TableRowColumn>{company.city_name || "–"}</TableRowColumn>
		                <TableRowColumn title={company.company_organization_name} style={{whiteSpace: "normal"}}>{company.company_organization_name || "–"}</TableRowColumn>
		                <TableRowColumn title={`${company.company_person_name || ""} ${company.company_person_surname || ""} ${company.company_person_patronymic || ""}`} style={{whiteSpace: "normal"}}>{`${company.company_person_name} ${company.company_person_surname} ${company.company_person_patronymic}`}</TableRowColumn>
		                { 
		                	<TableRowColumn>
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 2) &&
				                	<RaisedButton
				                		icon = {<Check color = "#fff"/>}
				                		backgroundColor="#a4c639"
				                		onClick = {this.valid.bind(this, company.company_id, 1)}
				                	/>
		                		}
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 1) &&
				                	<RaisedButton
				                		icon = {<DeleteForever color = "#fff"/>}
				                		secondary = {true}
				                		style = {{ marginLeft: "5px" }}
				                		onClick = {this.valid.bind(this, company.company_id, 0)}
				                	/>
		                		}
		                		{
		                			this.state.selectedIndex == 3 &&
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