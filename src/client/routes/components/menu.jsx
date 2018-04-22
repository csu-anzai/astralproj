import React from 'react';
import Drawer from 'material-ui/Drawer';
import {List, ListItem, makeSelectable} from 'material-ui/List';
import Home from 'material-ui/svg-icons/action/home';
import DonutSmall from 'material-ui/svg-icons/action/donut-small';
import FileDownload from 'material-ui/svg-icons/file/file-download';
import { push } from 'react-router-redux';
import { connect } from 'react-redux';
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