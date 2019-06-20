const env = require('../../env.json');
const mysql = require('mysql').createConnection(env.mysql);
const xlsx = require("xlsx");
const { performance } = require('perf_hooks');
const formatSheet = require("../../libs/formatSheet.js");

module.exports = env => {
  const connection = mysql.createConnection(env.mysql);
  return connection;
}

module.exports = (req, res) => {
  const workbook = xlsx.read(req.files.file.data, { type: 'buffer', raw: true });
  const table = formatSheet(workbook);

  const stats = {
    counter: 0,
    dubble: 0,
    new: 0,
    timeStart: performance.now()
  }

  statsUpdate = () => {
    if (++stats.counter == table.length) {
      stats.timeEnd = performance.now();
      res.send({
        ...stats,
        timeLoad: stats.timeEnd - stats.timeStart
      });
    }
  }

  table.map((c) => {
    mysql.query(
      `INSERT INTO companies (
        company_inn,
        company_ogrn,
        company_person_name,
        company_person_surname,
        company_person_patronymic,
        company_address,
        company_old_phone,
        company_old_email
      ) VALUES (${[
        c['inn'],
        c['ogrn'],
        c['name'],
        c['surname'],
        c['patronymic'],
        c['address'],
        c['phone'],
        c['email']
      ].map(i => mysql.escape(i)).join(', ')})`,
      (error, results, fields) => {
        if (error) {
          stats.dubble++;
          mysql.query({
            sql: `UPDATE companies SET company_old_phone = ?, company_old_email = ?, WHERE company_inn = ? LIMIT 1`,
            values: [c['phone'], c['email'], c['inn']]
          }, (error, results) => {
            statsUpdate();
          });
        } else {
          stats.new++;
          statsUpdate();
        }
    });
  })
}