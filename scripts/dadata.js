const env = require('../src/env.json');
const request = require('request');
const mysql = require('mysql');
const colors = require('colors');

const connection = mysql.createConnection(require('../src/env.json').mysql);
connection.connect();

let key = 0;

const run = () => {
  const startSelect = new Date().getTime();
  connection.query(`
    SELECT
      companies.company_id id,
      company_inn inn,
      company_address address
    FROM
      companies
    LEFT JOIN company_dadata_updates ON
      companies.company_id = company_dadata_updates.company_id
    WHERE
      company_okved_code is null AND
      company_dadata_updates.date is null
    LIMIT 1`,
    function (err, companies, fields) {
      const endSelect = new Date().getTime();
      key++;
      if(!err && companies.length > 0) {
        c = companies[0];
        const startDadata = new Date().getTime();
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
          const endDadata = new Date().getTime();
          connection.query(`INSERT INTO company_dadata_updates (company_id) VALUES (?)`, c.id);

          if (!err && body.suggestions && body.suggestions.length) {
            const { value, data } = body.suggestions[0];
            const companyName = value;
            const okvedCode = data.okved;
            const okvedName = (data.okveds && (data.okveds.find(o => o.code == okvedCode) || {} ).name) || "";
            const address = data.address && data.address.value;

            const startUpdate = new Date().getTime();
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
                [companyName, okvedCode, okvedName, (c.address || address), c.id],
                function (err, companies, fields) {
                  const endUpdate = new Date().getTime();
                  if (!err) {
                    console.log(
                      `${endSelect - startSelect}ms`.white,
                      `${endDadata - startDadata}ms`,
                      `${endUpdate - startUpdate}ms`,
                      key.toString().cyan,
                      c.inn.magenta,
                      `${companyName} ${okvedCode} ${address}`.green
                    );
                    run();
                  } else {
                    console.error(`${key} ${c.inn} Ошибка обновления`.red);
                    run();
                  }
                }
              );
            } else {
              run();
            }
          } else {
            console.log(`${key} ${c.inn} Ошибка загрузки данных`.yellow);
            run();
          }
        });
      } else console.log("END.");
    }
  );
}

run();
