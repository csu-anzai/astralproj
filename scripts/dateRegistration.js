const env = require('../src/env.json');
const request = require('request');
const mysql = require('mysql');
const colors = require('colors');
const moment = require('moment');

const connection = mysql.createConnection(require('../src/env.json').mysql);
connection.connect();
let key = 0;

const run = () => {
  console.log('='.repeat(100));
  const startSelect = new Date().getTime();
  connection.query(`
    SELECT
      companies.company_id id,
      companies.company_inn inn,
      company_date_registration dateRegistarion
    FROM companies
    JOIN templates
    ON companies.template_id = templates.template_id
    WHERE
      templates.channel_id = 2 AND
      companies.company_real_date_registration is null
    LIMIT 10`,
    function (err, companies, fields) {
      const endSelect = new Date().getTime();
      if(!err && companies.length > 0) {
        const l = companies.length - 1;
        companies.map((c, i) => {
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
              if (data.state && data.state.registration_date) {
                const realDateRegistration = moment(data.state.registration_date).format("YYYY-MM-DD");
                const startUpdate = new Date().getTime();

                connection.query(
                  `UPDATE
                    companies
                  SET
                    company_real_date_registration = ?
                  WHERE company_id = ?`,
                  [realDateRegistration, c.id],
                  function (err, companies, fields) {
                    const endUpdate = new Date().getTime();
                    if (!err) {
                      console.log(
                        `${endSelect - startSelect}ms`.white,
                        `${endDadata - startDadata}ms`,
                        `${endUpdate - startUpdate}ms`,
                        key.toString().cyan,
                        c.inn.magenta,
                        (c.dateRegistarion || "-").yellow,
                        realDateRegistration.green
                      );
                      key++; i == l && run();
                    } else {
                      console.error(`${key} ${c.inn} Ошибка обновления`.red);
                      key++; i == l && run();
                    }
                  }
                );
              } else {
                key++; i == l && run();
                console.log(`${key} ${c.inn} Нет информации про дату регистрации`.yellow);
              }
            } else {
              console.log(`${key} ${c.inn} Ошибка загрузки данных`.yellow);
              key++; i == l && run();
            }
          });

        })
      } else console.log("END.");
    }
  );
}

run();
