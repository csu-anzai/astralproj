import Download from './components/upload.jsx';
import { connect } from "react-redux";
export default connect(state => ({
	state: state.app.toJS()
}))(Download);