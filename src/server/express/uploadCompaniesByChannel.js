const env = require('../../env.json');
const mysql = require('mysql').createConnection(env.mysql);
const xlsx = require("xlsx");
const { performance } = require('perf_hooks');
const formatSheet = require("../../libs/formatSheet.js");

module.exports = (req, res, body) => {
  const stats = {
    counter: 0,
    dubble: 0,
    new: 0,
    errors: 0,
    timeStart: performance.now()
  }

  const workbook = xlsx.read(req.files.file.data, { type: 'buffer', cellDates: true, raw: true });

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

  createLeads = (table, templates) => table.map((c) => {
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
          company_date_registration,
          company_view_priority,
          template_id
        ) VALUES (${[
          c.inn,
          c.ogrn,
          c.name,
          c.surname,
          c.patronymic,
          c.address,
          c.phone,
          c.email,
          c.regDate,
          priority,
          templates.find(t => t.type == (c.inn.toString().length === 12 ? 11 : 12)).id
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
  // const typeId = table[0].inn.toString().length === 12 ? 11 : 12; // ИП или ООО
  const priority = req.body.priority || 1;

  mysql.query(
    `SELECT template_id id, type_id type FROM templates WHERE channel_id = ?`,
    [channelId],
    (error, result, fields) => {
      if (result.length == 2) {
        createLeads(table, result);
      } else {
        res.send({ error: "Нет шаблонов для канала" })
      }
      // else {
      //   mysql.query(
      //     `INSERT INTO templates (type_id, channel_id) VALUES (?, ?);`,
      //     [typeId, channelId],
      //     (error, result, fields) => {
      //       createLeads(table, result.insertId);
      //     }
      //   );
      // }
    }
  );
}
