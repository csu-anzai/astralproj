const env = require('../../env.json');
const mysql = require('mysql').createConnection(env.mysql);

module.exports = (req, res) => {
  mysql.query(
    `SELECT
      channel_id id,
      channel_description name,
      channel_priority priority
    FROM channels`,
    (error, results, fields) => {
      res.send({ channels: results });
    }
  );
}
