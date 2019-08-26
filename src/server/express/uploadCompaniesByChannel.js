const env = require('../../env.json');
const request = require('request');
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
    dadata: 0,
    timeStart: performance.now()
  }

  const workbook = xlsx.read(req.files.file.data, { type: 'buffer', cellDates: true, raw: true });

  const table = formatSheet(workbook);

  statsUpdate = () => {
    if (++stats.counter == table.length) {

      mysql.query(
        `UPDATE
          companies set company_json = json_set(company_json, "$.company_id", company_id)
        WHERE company_json ->> "$.company_id" is null or company_json ->> "$.company_id" != company_id`,
        (error, result, fields) => {}
      ); // Борьба с багом нуливого id в json

      stats.timeEnd = performance.now();
      res.send({
        ...stats,
        timeLoad: stats.timeEnd - stats.timeStart
      });
    }
  }

  createLeads = (table, templates) => table.map((c) => {
    if(c.inn && c.phone && c.name) {

      request({
        url: 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/findById/party',
        json: true,
        method: 'POST',
        headers: {
          'Authorization': 'Token ' + env.dadata.token,
          'content-type': 'application/json'
        },
        body: { "query": c.inn }
      }, (err, res, body) => {
        let companyName = "";
        let okvedCode = "";
        let okvedName = "";

        if (!err && body.suggestions && body.suggestions.length) {
          stats.dadata++;
          const { value, data } = body.suggestions[0];
          companyName = value;
          okvedCode = data.okved;
          okvedName = data.okveds ? data.okveds.find(o => o.code == data.okved).name : "";
          if (!c.address) c.address = data.address && data.address.value;
        } else {
          if (c.inn.length == 12) {
            companyName = ["ИП", c.surname, c.name, c.patronymic].join(" ");
          } else {
            companyName = 'ООО "Драйв"';
          }
        }

        console.log(c.inn, companyName);

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
            company_organization_name,
            company_okved_code,
            company_okved_name,
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
            companyName,
            okvedCode,
            okvedName,
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
      });
    } else {
      stats.errors++;
      statsUpdate();
    }
  })

  const channelId = parseInt(req.body.channelId);
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
    }
  );
}
