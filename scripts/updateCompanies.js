const request = require('request');
const mysql = require('mysql');
const colors = require('colors');

const connection = mysql.createConnection(require('../src/env.json').mysql);
connection.connect();

connection.query(`
  SELECT
    company_inn inn,
    company_id id,
    company_json json
  FROM companies
  WHERE
    company_organization_name is NULL AND
    company_inn is not NULL AND
    company_date_create > "2019-08-20"
  `,
  function (err, companies, fields) {
    if(!err) {
      companies.map(c => {
        request({
            url: 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/findById/party',
            json: true,
            method: 'POST',
            headers: {
              'Authorization': 'Token e2b227d479df216b3d7e436950e20aa0924fd075',
              'content-type': 'application/json'
            },
            body: { "query": c.inn }
        }, (err, res, body) => {
          if(!err) {
            if (body.suggestions.length) {
              const { value, data } = body.suggestions[0];
              const name = value;
              const okvedCode = data.okved;
              const okvedName = data.okveds ? data.okveds.find(o => o.code == data.okved).name : "";

              const json = JSON.stringify({
                ...JSON.parse(c.json),
                company_organization_name: name,
                company_okved_code: okvedCode,
                company_okved_name: okvedName
              });

              connection.query(
                `UPDATE companies SET company_okved_code = ?, company_okved_name = ?, company_json = ? WHERE company_id = ?;`,
                [okvedCode, okvedName, json, c.id],
                function (err, companies, fields) {
                  if (!err) {
                    console.log(`${c.inn} ${name}, ${okvedCode}, ${okvedName}`.green);
                  } else {
                    console.error(`${c.inn} Ошибка обновления`.red);
                  }
                }
              );
            } else {
              console.error(`${c.inn} Нет информации о компании`.red);
            }
          } else {
            console.error(`${c.inn} Ошибка загрузки данных`.red);
          }
        });
      })
    } else {
      console.error(`Ошибка загрузки лидов из БД`.red);
    }
  }
);
