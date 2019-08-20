const env = require('../../env.json');
const mysql = require('mysql').createConnection(env.mysql);
const xlsx = require("xlsx");
const { performance } = require('perf_hooks');
const formatSheet = require("../../libs/formatSheet.js");

module.exports = env => {
  const connection = mysql.createConnection(env.mysql);
  return connection;
}

module.exports = (req, res, body) => {

  const stats = {
    counter: 0,
    dubble: 0,
    new: 0,
    errors: 0,
    timeStart: performance.now()
  }

  const workbook = xlsx.read(req.files.file.data, { type: 'buffer', raw: true });
  const table = formatSheet(workbook);

  statsUpdate = () => {
    if (++stats.counter == table.length) {
      stats.timeEnd = performance.now();
      res.send({
        ...stats,
        timeLoad: stats.timeEnd - stats.timeStart
      });
    }
  }


  createLeads = (table, templatesId) => table.map((c) => {
    if(c.inn && c.phone && c.name) {
      mysql.query(
        `INSERT INTO companies (
          company_inn,
          company_ogrn,
          company_person_name,
          company_person_surname,
          company_person_patronymic,
          company_address,
          company_phone,
          company_email,
          template_id
        ) VALUES (${[
          c['inn'],
          c['ogrn'],
          c['name'],
          c['surname'],
          c['patronymic'],
          c['address'],
          c['phone'],
          c['email'],
          templatesId
        ].map(i => mysql.escape(i)).join(', ')})`,
        (error, results, fields) => {
          if (error) {
            if (error.code == "ER_DUP_ENTRY") {
              stats.dubble++;
            } else {
              stats.errors++;
            }
            statsUpdate();
          } else {
            stats.new++;
            statsUpdate();
          }
      });
    } else {
      stats.errors++;
      statsUpdate();
    }
  })

  const channelId = parseInt(req.body.channelId);
  const typeId = table[0].inn.toString().length === 12 ? 11 : 12; // ИП или ООО

  mysql.query(
    `SELECT template_id FROM templates WHERE type_id = ? AND channel_id = ? LIMIT 1`,
    [typeId, channelId],
    (error, result, fields) => {
      if (result.length) {
        createLeads(table, result[0].template_id);
      } else {
        mysql.query(
          `INSERT INTO templates (type_id, channel_id) VALUES (?, ?);`,
          [typeId, channelId],
          (error, result, fields) => {
            createLeads(table, result.insertId);
          }
        );
      }
    }
  );
}
