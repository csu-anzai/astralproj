import Login from './components/login';
import { connect } from 'react-redux';
export default connect(state => ({
	state: state.app.toJS()
}))(Login);