import React from 'react';
import Paper from 'material-ui/Paper';
import RaisedButton from 'material-ui/RaisedButton';
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';
import CircularProgress from 'material-ui/CircularProgress';
import axios from 'axios';
import { ws } from '../../../../../env.json';

export default class Download extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      fileName: null,
      channelId: 1,
      loading: false,
      stats: false,
      error: false,
      errors: 0,
    }
  }

  handleChange(e) {
    const formData = new FormData();

    const file = e.currentTarget.files[0];
    formData.append('file', file);
    formData.append('channelId', this.state.channelId);

    this.setState({
      loading: true,
      stats: false,
      error: false,
      errors: 0,
      fileName: file.name
    });

    axios.post(`${ws.location}:${ws.port}/api/uploadCompaniesByChannel`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
    }).then((response) => {
      this.setState({
        stats: response.data,
        loading: false,
        error: false
      });
    }).catch(err => {
      this.setState({
        loading: false,
        error: true
      });
    });

  }

  handleFile() {
    this.refs.file.click();
  }

  handleChannelChange(e, n, value) {
    this.setState({ channelId: value });
  }

  render(){
    const { state } = this;
    const { stats, error, loading, fileName } = state;
    return (
      <div>
        <Paper style={{
          margin: '5em',
          maxWidth: '450px',
          padding: '3em'
        }} zDepth={1}>
          <input style={{display: 'none'}} ref="file" type="file" onChange={this.handleChange.bind(this)} />
          <h1>Загрузка лидов по отдельному каналу</h1>
          <p>Выберите канал и загрузите файл с лидами</p>
          <SelectField
            floatingLabelText="Канал"
            value={this.state.channelId}
            onChange={this.handleChannelChange.bind(this)}
            autoWidth={true}
          >
            <MenuItem value={1} primaryText="Первый" />
            <MenuItem value={2} primaryText="Второй" />
          </SelectField>
          { loading ? <div>
            <p>Обработка: <b>{fileName}</b></p>
            <CircularProgress />
          </div> : (
            <p>
              <RaisedButton
                label="Загрузить xls"
                backgroundColor="#2196f3"
                labelColor = "#fff"
                key={1}
                onClick={this.handleFile.bind(this)}
              />
             </p>
          )}
          {stats && <div>
            <ul>
              <li>Всего обработано: <b>{stats.counter}</b></li>
              <li>Новых Лидов: <b>{stats.new}</b></li>
              <li>Дублий: <b>{stats.dubble}</b></li>
              <li>Ошибок: <b>{stats.errors}</b></li>
              <li>Время выполнения: <b>{(stats.timeLoad / 1000).toFixed(3) } секунд</b></li>
            </ul>
          </div>}
          {error && <p><b style={{color: "red"}}>Ошибка сервера</b></p>}
        </Paper>
      </div>
    )
  }
}
