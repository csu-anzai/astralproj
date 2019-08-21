import React from 'react';
import Drawer from 'material-ui/Drawer';
import {List, ListItem, makeSelectable} from 'material-ui/List';
import Home from 'material-ui/svg-icons/action/home';
import DonutSmall from 'material-ui/svg-icons/action/donut-small';
import ArrowUpward from 'material-ui/svg-icons/navigation/arrow-upward';
import FileDownload from 'material-ui/svg-icons/file/file-download';
import { push } from 'react-router-redux';
import { connect } from 'react-redux';
import Divider from 'material-ui/Divider';
import Avatar from 'material-ui/Avatar';
let SelectableList = makeSelectable(List);
function wrapState(ComposedComponent) {
  return class SelectableList extends React.Component {
    handleRequestChange(event, index){
      this.props.onChange(index);
    };
    render() {
      return (
        <ComposedComponent
          value={this.props.defaultValue}
          onChange={this.handleRequestChange.bind(this)}
        >
          {this.props.children}
        </ComposedComponent>
      );
    }
  };
}
SelectableList = wrapState(SelectableList);
class Menu extends React.Component {
  changePage(page){
    this.props.dispatch(push(page));
    this.props.dispatch({type: "changeMenuState"});
  }
	render(){
		return <Drawer
			open = { this.props.state.menuSwitch || false }
			docked = { false }
			onRequestChange = { this.props.dispatch.bind(this, {type: "changeMenuState"}) }
		>
      <Avatar
        style = {{
          margin: "8px",
          background: "#00bcd4"
        }}
      >
        {this.props.state.userName && this.props.state.userName.split(" ").map(i => i[0]).join("").slice(0,2)}
      </Avatar>
      <div
        style = {{
          display: "inline-block",
          verticalAlign: "top",
          paddingTop: "10px"
        }}
      >
        <span
          style = {{
            fontSize: "14px"
          }}
        >
          {this.props.state.userName && this.props.state.userName.split(" ").filter((i,k) => k < 2).join(" ")}
        </span> <br/>
        <span
          style = {{
            fontSize: "12px"
          }}
        >
          {this.props.state.userEmail}
        </span>
      </div>
      <Divider/>
			<SelectableList
				defaultValue = {this.props.routing.location && this.props.routing.location.pathname}
        onChange = {this.changePage.bind(this)}
			>
        {
          (this.props.state.userType == 1 || this.props.state.userType == 18) &&
          <ListItem
            primaryText = "Компании"
            leftIcon = { <Home/> }
            value = "/tinkoff"
          />
        }
        {
          (this.props.state.userType == 1 || this.props.state.userType == 19) &&
          <ListItem
            primaryText = "Статистика"
            leftIcon = { <DonutSmall/> }
            value = "/supervisor"
          />
        }
        {
          (this.props.state.userType == 1 || this.props.state.userType == 19) &&
          <ListItem
            primaryText = "Загрузка старой базы"
            leftIcon = { <ArrowUpward/> }
            value = "/upload"
          />
        }
        {
          (this.props.state.userType == 1 || this.props.state.userType == 19) &&
          <ListItem
            primaryText = "Загрузка базы по каналу"
            leftIcon = { <ArrowUpward/> }
            value = "/uploadChannel"
          />
        }
        {
          this.props.state.userType == 1 &&
          <ListItem
            primaryText = "Ручная выгрузка"
            leftIcon = { <FileDownload/> }
            value = "/download"
          />
        }
			</SelectableList>
		</Drawer>
	}
}
export default connect(state => ({
	state: state.app.toJS(),
  routing: state.routing
}))(Menu);
