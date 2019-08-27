const env = require('../src/env.json');
const request = require('request');
const mysql = require('mysql');
const colors = require('colors');

const connection = mysql.createConnection(require('../src/env.json').mysql);
connection.connect();


connection.query(`
  SELECT
    companies.company_id id,
    company_inn inn
  FROM
    companies
  LEFT JOIN company_dadata_updates ON
    companies.company_id = company_dadata_updates.company_id
  WHERE
    company_okved_code is null AND
    company_dadata_updates.date is null
  LIMIT 50000`,
  function (err, companies, fields) {
    if(!err) {
      companies.forEach((c, key) => {
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
          if (!err && body.suggestions && body.suggestions.length) {
            const { value, data } = body.suggestions[0];
            const companyName = value;
            const okvedCode = data.okved;
            const okvedName = data.okveds ? data.okveds.find(o => o.code == okvedCode).name : "";
            const address = data.address && data.address.value;

            connection.query(`INSERT INTO company_dadata_updates (company_id) VALUES (?)`, c.id);

            if (okvedCode) {
              connection.query(
                `UPDATE
                  companies
                SET
                  company_organization_name = ?,
                  company_okved_code = ?,
                  company_okved_name = ?,
                  company_address = ?
                WHERE company_id = ?`,
                [companyName, okvedCode, okvedName, address, c.id],
                function (err, companies, fields) {
                  if (!err) {
                    console.log(`${c.inn} ${companyName} ${okvedCode} ${address}`.green);
                  } else {
                    console.error(`${c.inn} Ошибка обновления`.red);
                  }
                }
              );
            }
          } else {
            console.log(`${c.inn} Ошибка загрузки данных`.yellow);
          }
        });
      });
    }
  }
);
