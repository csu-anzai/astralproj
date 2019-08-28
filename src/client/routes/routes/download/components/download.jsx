import React from 'react';
import {BottomNavigation, BottomNavigationItem} from 'material-ui/BottomNavigation';
import {List, ListItem} from 'material-ui/List';
import Build from 'material-ui/svg-icons/action/build';
import Favorite from 'material-ui/svg-icons/action/favorite';
import Folder from 'material-ui/svg-icons/file/folder';
import Paper from 'material-ui/Paper';
import Divider from 'material-ui/Divider';
import FlatButton from 'material-ui/FlatButton';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import DatePicker from 'material-ui/DatePicker';
import TextField from 'material-ui/TextField';
import { Redirect } from 'react-router';
import { ws } from '../../../../../env.json';
import {
  Table,
  TableBody,
  TableFooter,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn,
} from 'material-ui/Table';
let selectorsStyle = {
  marginLeft: "5px",
  textAlign: "left"
}
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
  },
  {
    type_id: 10,
    type_name: "Свободные"
  },
  {
    type_id: 24,
    type_name: "Дубликаты"
  }
];
export default class Download extends React.Component {
  constructor(props){
    super(props);
    this.state = {
      select: 0
    }
    this.createFile = this.createFile.bind(this);
    this.reserveCompanies = this.reserveCompanies.bind(this);
  }
  componentDidMount(){
    let component = document.querySelector("#app > div > div:nth-child(2) > div > div > div");
    component && (component.style.overflow = "auto");
  }
  createFile(){
    this.props.dispatch({
      type: "query",
      socket: true,
      data: {
        query: "createDownloadFile",
        values: [
          this.props.state.connectionHash
        ]
      }
    })
  }
  reserveCompanies(){
    this.props.dispatch({
      type: "procedure",
      socket: true,
      data: {
        query: "reserveCompanies",
        values: [
          this.props.state.connectionHash
        ]
      }
    })
  }
  changeMultipleFilter(type, event, key, payload){
    if(payload.indexOf(0) != -1 && payload.indexOf(0) != 0){
      payload = [];
    } else {
      payload = payload.filter(i => i != 0);
    }
    this.props.dispatch({
      type: "query",
      socket: true,
      data: {
        query: "setDownloadFilter",
        values: [
          this.props.state.connectionHash,
          JSON.stringify({
            [type]: payload
          })
        ]
      }
    });
  }
  changeSingleFilter(type, event, key, payload){
    this.props.dispatch({
      type: "query",
      socket: true,
      data: {
        query: "setDownloadFilter",
        values: [
          this.props.state.connectionHash,
          JSON.stringify({
            [type]: payload
          })
        ]
      }
    });
  }
  changeDataFilter(type, eny, date){
    this.props.dispatch({
      type: "query",
      socket: true,
      data: {
        query: "setDownloadFilter",
        values: [
          this.props.state.connectionHash,
          JSON.stringify({
            [type]: `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`
          })
        ]
      }
    });
  }
  inputNumberFilter(type, event, value){
    this.props.dispatch({
      type: "query",
      socket: true,
      data: {
        query: "setDownloadFilter",
        values: [
          this.props.state.connectionHash,
          JSON.stringify({
            [type]: value
          })
        ]
      }
    });
  }
  select(num){
    this.setState({
      select: num
    })
  }
  render(){
    return <div>
      <Paper zDepth={0}>
        <BottomNavigation selectedIndex={this.state.select}>
          <BottomNavigationItem
            label="СОЗДАНИЕ ФАЙЛА"
            icon={<Build/>}
            onClick={this.select.bind(this, 0)}
          />
          <BottomNavigationItem
            label={"ВСЕ ФАЙЛЫ (" + (this.props.state.files ? this.props.state.files.length : 0) + ")"}
            icon={<Folder/>}
            onClick={this.select.bind(this, 1)}
          />
          <BottomNavigationItem
            label={"БЫСТРЫЙ ЭКСПОРТ"}
            icon={<Folder/>}
            href={`${ws.location}:${ws.port}/api/exportLeads`}
          />
        </BottomNavigation>
        {
          this.state.select == 0 &&
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
                <TableHeaderColumn colSpan = {(this.props.state.downloadCompaniesColumnsNames && this.props.state.downloadCompaniesColumnsNames.length > 0 && this.props.state.downloadCompaniesColumnsNames.length) || (this.props.state.columns && this.props.state.columns.length > 0 && this.props.state.columns.length) || 1}>
                  <div style = {{textAlign: "center", maxWidth: "100vw"}}>
                    <SelectField
                      floatingLabelText="Банки"
                      value = {this.props.state.download && (this.props.state.download.banks.length > 0 ? this.props.state.download.banks : [0]) || [0]}
                      multiple = {true}
                      onChange = {this.changeMultipleFilter.bind(this, "banks")}
                      style = {{textAlign: "left"}}
                      autoWidth = {true}
                    >
                      <MenuItem value = {0} primaryText = "Не учитывать" />
                      <MenuItem value = {null} primaryText = "Без банка" />
                      {
                        this.props.state.banks && this.props.state.banks.map((bank, key) => (
                          <MenuItem value = {bank.id} key = {key} primaryText = {bank.name} />
                        ))
                      }
                    </SelectField>
                    <SelectField
                      floatingLabelText="Регионы"
                      value = {this.props.state.download && (this.props.state.download.regions.length > 0 ? this.props.state.download.regions : [0]) || [0]}
                      multiple = {true}
                      onChange = {this.changeMultipleFilter.bind(this, "regions")}
                      style = {selectorsStyle}
                      autoWidth = {true}
                    >
                      <MenuItem value = {0} primaryText = "Не учитывать" />
                      <MenuItem value = {null} primaryText = "Без региона" />
                      {
                        this.props.state.regions && this.props.state.regions.map((region, key) => (
                          <MenuItem value = {region.id} key = {key} primaryText = {region.name} />
                        ))
                      }
                    </SelectField>
                    <SelectField
                      floatingLabelText="Пустые поля"
                      value = {this.props.state.download && (this.props.state.download.nullColumns.length > 0 ? this.props.state.download.nullColumns : [0]) || [0]}
                      multiple = {true}
                      onChange = {this.changeMultipleFilter.bind(this, "nullColumns")}
                      style = {selectorsStyle}
                      autoWidth = {true}
                    >
                      <MenuItem value = {0} primaryText = "Не учитывать" />
                      {
                        this.props.state.regions && this.props.state.columns.map((column, key) => (
                          <MenuItem value = {column.id} key = {key} primaryText = {column.name} />
                        ))
                      }
                    </SelectField>
                    <SelectField
                      floatingLabelText="Заполненые поля"
                      value = {this.props.state.download && (this.props.state.download.notNullColumns.length > 0 ? this.props.state.download.notNullColumns : [0]) || [0]}
                      multiple = {true}
                      onChange = {this.changeMultipleFilter.bind(this, "notNullColumns")}
                      style = {selectorsStyle}
                      autoWidth = {true}
                    >
                      <MenuItem value = {0} primaryText = "Не учитывать" />
                      {
                        this.props.state.regions && this.props.state.columns.map((column, key) => (
                          <MenuItem value = {column.id} key = {key} primaryText = {column.name} />
                        ))
                      }
                    </SelectField>
                    <SelectField
                      floatingLabelText="Тип"
                      value = {this.props.state.download && this.props.state.download.types}
                      style = {selectorsStyle}
                      onChange = {this.changeMultipleFilter.bind(this, "types")}
                      autoWidth = {true}
                      multiple = {true}
                      floatingLabelFixed = {true}
                      selectionRenderer = {values => values.length == 0 ? "Не учитывать" : values.length == 1 ? typeNames.find(i => i.type_id == values[0]).type_name : `Выбрано типов: ${values.length}`}
                    >
                      <MenuItem value = {10} primaryText = "Свободные" />
                      <MenuItem value = {24} primaryText = "Дубликаты" />
                      <MenuItem value = {13} primaryText = "Утверждено" />
                      <MenuItem value = {14} primaryText = "Не интересно" />
                      <MenuItem value = {36} primaryText = "Нет связи" />
                      <MenuItem value = {23} primaryText = "Перезвонить" />
                      <MenuItem value = {37} primaryText = "Сложные" />
                      <MenuItem value = {35} primaryText = "Рабочий список: первичный недозвон" />
                      <MenuItem value = {9} primaryText = "Рабочий список: в работе" />
                    </SelectField>
                    <div>
                      <DatePicker
                        floatingLabelText="Начальная дата"
                        defaultDate = {(this.props.state.download && this.props.state.download.dateStart) ? new Date(this.props.state.download.dateStart) : new Date()}
                        style = {{display: "inline-block", marginRight: "5px"}}
                        onChange = {this.changeDataFilter.bind(this, "dateStart")}
                      />
                      <DatePicker
                        floatingLabelText="Конечная дата"
                        style = {{display: "inline-block", marginRight: "5px"}}
                        defaultDate = {(this.props.state.download && this.props.state.download.dateEnd) ? new Date(this.props.state.download.dateEnd) : new Date()}
                        onChange = {this.changeDataFilter.bind(this, "dateEnd")}
                      />
                      <TextField
                        type = "number"
                        floatingLabelText = "Количество в файле"
                        value = {this.props.state.download && this.props.state.download.count || 100}
                        onChange = {this.inputNumberFilter.bind(this, "count")}
                      />
                      <TextField
                        type = "number"
                        floatingLabelText = "Количество на экране"
                        value = {this.props.state.download && this.props.state.download.limit || 50}
                        onChange = {this.inputNumberFilter.bind(this, "limit")}
                      />
                      <TextField
                        type = "number"
                        floatingLabelText = "Строка начала показа"
                        value = {this.props.state.download && this.props.state.download.offset || 0}
                        onChange = {this.inputNumberFilter.bind(this, "offset")}
                      />
                    </div>
                    <div style = {{textAlign: "center", margin: "5px 0 10px"}}>
                      <FlatButton
                        label = "Зарезервировать компании"
                        primary = {true}
                        style = {{display: "inline-block"}}
                        disabled = {this.props.state.download && !this.props.state.download.companiesCount ? false : true}
                        onClick = {this.reserveCompanies}
                      />
                      <FlatButton
                        label = {"Создать файл (" + (this.props.state.download && this.props.state.download.companiesCount || 0) + ")"}
                        primary = {true}
                        style = {{display: "inline-block"}}
                        disabled = {this.props.state.download && this.props.state.download.companiesCount > 0 ? false : true}
                        onClick = {this.createFile}
                      />
                    </div>
                    {
                      this.props.state.download && this.props.state.download.fileURL &&
                      <div style = {{textAlign: "center", margin: "5px 0 15px"}}>
                        Ссылка на файл: {" "}
                        <a href = {this.props.state.download.fileURL} target = "_blank" style = {{textDecoration: "none", color: "#00bcd4", cursor: "pointer"}}>{this.props.state.download.fileURL}</a>
                      </div>
                    }
                  </div>
                </TableHeaderColumn>
              </TableRow>
              <TableRow>
                {
                  this.props.state.downloadCompaniesColumnsNames && this.props.state.downloadCompaniesColumnsNames.length > 0 && Object.keys(this.props.state.downloadCompanies[0]).map((column, key) => (
                    <TableHeaderColumn key = {key}>{this.props.state.downloadCompaniesColumnsNames.find(item => item.param == column).name}</TableHeaderColumn>
                  )) ||
                  <TableHeaderColumn style = {{textAlign: "center"}}>
                    {
                      this.props.state.download && this.props.state.download.message || "Нет загруженных данных"
                    }
                  </TableHeaderColumn>
                }
              </TableRow>
            </TableHeader>
            <TableBody
              displayRowCheckbox={false}
              deselectOnClickaway={false}
              showRowHover={true}
              stripedRows={false}
            >
              {
                this.props.state.downloadCompanies && this.props.state.downloadCompanies.map((company, rowKey) => (
                  <TableRow key = {rowKey}>
                    {
                      Object.keys(company).map((paramName, columnKey) => (
                        <TableRowColumn key = {columnKey}>
                          { company[paramName] || "—" }
                        </TableRowColumn>
                      ))
                    }
                  </TableRow>
                ))
              }
            </TableBody>
          </Table>
        }
        {
          this.state.select == 1 &&
          <div style = {{textAlign: "center"}}>
            <List style = {{display: "inline-block", textAlign: "left"}}>
              {
                this.props.state.files && this.props.state.files.map((file, key) => (
                  <ListItem key = {key}>
                    <a href = {file.name} target = "_blank" style = {{textDecoration: "none", color: "#00bcd4", cursor: "pointer"}}>
                      {file.name}
                    </a>
                  </ListItem>
                ))
              }
            </List>
          </div>
        }
      </Paper>
    </div>
  }
}
