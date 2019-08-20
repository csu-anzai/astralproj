import UploadChannel from './components/uploadChannel.jsx';
import { connect } from "react-redux";
export default connect(state => ({
	state: state.app.toJS()
}))(UploadChannel);
