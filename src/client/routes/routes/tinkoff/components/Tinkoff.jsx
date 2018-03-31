import React from 'react';
import { Redirect } from 'react-router';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';
import Restore from 'material-ui/svg-icons/action/restore';
import Favorite from 'material-ui/svg-icons/action/favorite';
import HighlightOff from 'material-ui/svg-icons/action/highlight-off';
import Check from 'material-ui/svg-icons/navigation/check';
import DeleteForever from 'material-ui/svg-icons/action/delete-forever';
import Paper from 'material-ui/Paper';
import RaisedButton from 'material-ui/RaisedButton';
import Badge from 'material-ui/Badge';
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
			selectedIndex: 0
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
				values: [
					this.props.state.connectionHash,
					25
				]
			}
		});
	}
	upload(){
		let uploadCompanies = this.props.state.companies.filter(item => item.typeID == 13).map(i => i.companyID);
		this.props.dispatch({
			type: "query",
			socket: true,
			data: {
				query: "sendToApi",
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
				values: [
					this.props.state.connectionHash,
					company_id,
					valid
				]
			}
		});
	}
	render(){
		return <div>
			<Paper zDepth={1}>
				<BottomNavigation selectedIndex={this.state.selectedIndex}>
					<BottomNavigationItem
            label={"В РАБОТЕ ("+(this.props.state.companies && this.props.state.companies.filter(i => i.typeID == 10 || i.typeID == 9).length || 0)+")"}
            icon={<Restore/>}
            onClick={() => this.select(0)}
          />
          <BottomNavigationItem
            label={"ИНТЕРЕСНО ("+(this.props.state.companies && this.props.state.companies.filter(i => i.typeID == 13).length || 0)+")"}
            icon={<Favorite/>}
            onClick={() => this.select(1)}
          />
          <BottomNavigationItem
            label={"НЕ ИНТЕРЕСНО ("+(this.props.state.companies && this.props.state.companies.filter(i => i.typeID == 14).length || 0)+")"}
            icon={<HighlightOff/>}
            onClick={() => this.select(2)}
          />
				</BottomNavigation>
				<Table
          fixedHeader={true}
          fixedFooter={false}
          selectable={false}
          multiSelectable={false}
        >
	          <TableHeader
	            displaySelectAll={false}
	            adjustForCheckbox={false}
	            enableSelectAll={false}
	          >
	            <TableRow>
	              <TableHeaderColumn colSpan="6" style={{textAlign: 'right'}}>
	              	{
	              		(!this.props.state.companies || 
	              		this.props.state.companies.filter(company => company.typeID == 13).length == 0) &&
		                <RaisedButton 
		                	label = "Обновить список"
		                	backgroundColor="#a4c639"
		                	labelColor = "#fff"
		                	onClick = {()=>{this.refresh.call(this)}}
		                /> ||
		                <RaisedButton 
		                	label = "Утвердить список интересных компаний"
		                	backgroundColor="#FF5722"
		                	labelColor = "#fff"
		                	onClick = {()=>{this.upload.call(this)}}
		                />
	              	}
	              </TableHeaderColumn>
	            </TableRow>
	            <TableRow>
	              <TableHeaderColumn>Телефон</TableHeaderColumn>
	              <TableHeaderColumn>Тип компании</TableHeaderColumn>
	              <TableHeaderColumn>ИНН</TableHeaderColumn>
	              <TableHeaderColumn>Регион</TableHeaderColumn>
	              <TableHeaderColumn>Город</TableHeaderColumn>
              	<TableHeaderColumn>Действия</TableHeaderColumn>
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
		              ((this.state.selectedIndex == 1 && company.typeID == 13) || (this.state.selectedIndex == 2 && company.typeID == 14) || (this.state.selectedIndex == 0 && (company.typeID == 10 || company.typeID == 9))) &&
		              <TableRow key = {key}>
		                <TableRowColumn>{company.companyPhone}</TableRowColumn>
		                <TableRowColumn>{company.templateID == 1 ? "ИП" : "ООО"}</TableRowColumn>
		                <TableRowColumn>{company.companyInn}</TableRowColumn>
		                <TableRowColumn>{company.regionName}</TableRowColumn>
		                <TableRowColumn>{company.cityName}</TableRowColumn>
		                { 
		                	<TableRowColumn>
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 2) &&
				                	<RaisedButton
				                		icon = {<Check color = "#fff"/>}
				                		backgroundColor="#a4c639"
				                		onClick = {this.valid.bind(this, company.companyID, 1)}
				                	/>
		                		}
		                		{
		                			(this.state.selectedIndex == 0 || this.state.selectedIndex == 1) &&
				                	<RaisedButton
				                		icon = {<DeleteForever color = "#fff"/>}
				                		secondary = {true}
				                		style = {{ marginLeft: "5px" }}
				                		onClick = {this.valid.bind(this, company.companyID, 0)}
				                	/>
		                		}
			                </TableRowColumn>
		                }
		              </TableRow>
	          		)) || 
	          		<TableRow>
	          			<TableRowColumn 
	          				colSpan = "6"
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
		</div>
	}
}