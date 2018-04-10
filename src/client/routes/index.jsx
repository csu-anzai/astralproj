import Main from './components/main';
import Childrens from './routes';
import React from 'react';
import { connect } from 'react-redux';
const MainObjectConnection = connect(state => ({
	state: state.app.toJS(),
	routing: state.routing
}))(Main);
const MainObject = <MainObjectConnection childrens = {<Childrens/>}/>;
export default MainObject;