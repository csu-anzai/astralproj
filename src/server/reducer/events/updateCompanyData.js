const mysql = require('mysql');
const request = require('request');
const colors = require('colors');
const env = require('../../../env.json');

module.exports = modules => (resolve, reject, data) => {
  const connection = mysql.createConnection(env.mysql);
  connection.connect();
  modules.mysql.query(`
    SELECT
      company_id id,
      company_inn inn
    FROM
      companies
    WHERE
      company_okved_code is null AND
      company_date_create > NOW()  - INTERVAL 5 MINUTE
    LIMIT 10`,
    function (err, companies, fields) {
      console.log("companies".green, companies);
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


}
