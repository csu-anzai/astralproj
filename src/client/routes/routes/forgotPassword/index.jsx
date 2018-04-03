import ForgotPassword from './components/forgotPassword';
import { connect } from 'react-redux';
export default connect(state => ({
	state: state.app.toJS()
}))(ForgotPassword);