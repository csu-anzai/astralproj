import React from 'react';
import Drawer from 'material-ui/Drawer';
import {List, ListItem, makeSelectable} from 'material-ui/List';
import Home from 'material-ui/svg-icons/action/home';
import { connect } from 'react-redux';
let SelectableList = makeSelectable(List);
function wrapState(ComposedComponent) {
  return class SelectableList extends React.Component {
    handleRequestChange(event, index){
      this.props.onChange({
      	type: "changePage",
      	data: {
      		page: index
      	}
      });
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
	render(){
		return <Drawer 
			open = { this.props.state.menuSwitch || false }
			docked = { false }
			onRequestChange = { this.props.dispatch.bind(this, {type: "changeMenuState"}) }
		>
			<SelectableList
				defaultValue = {this.props.state.page || 1}
				onChange = {this.props.dispatch}
			>
				<ListItem 
					primaryText = "Компании" 
					leftIcon = { <Home/> }
					value = {1}
				/>
			</SelectableList>
		</Drawer>
	}
}
export default connect(state => ({
	state: state.app.toJS()
}))(Menu);