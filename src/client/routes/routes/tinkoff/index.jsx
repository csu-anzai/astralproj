import Tinkoff from './components/Tinkoff';
import { connect } from "react-redux";
export default connect(state => ({
	state: state.app.toJS()
}))(Tinkoff);