import { connect } from "react-redux";
import Supervisor from "./components/supervisor";
export default connect(state => ({
	state: state.app.toJS()
}))(Supervisor);