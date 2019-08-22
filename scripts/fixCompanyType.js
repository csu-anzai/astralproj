const request = require('request');
const mysql = require('mysql');
const colors = require('colors');

const connection = mysql.createConnection(require('../src/env.json').mysql);
connection.connect();

connection.query(`
  SELECT
    company_inn inn,
    company_json json,
    company_id id,
    company_person_name name,
    company_person_surname surname,
    company_person_patronymic patronymic
  FROM
    companies
  JOIN
    templates
  ON
    companies.template_id = templates.template_id
  WHERE
    templates.channel_id = 2`,
  function (err, companies, fields) {
    companies.map(c => {

      if (c.inn.length == 12) {

        const templateId = 14;

        const companyName = ["ИП", c.surname, c.name, c.patronymic].join(" ");
        const json = JSON.stringify({
          ...JSON.parse(c.json),
          company_organization_name: companyName,
          template_id: templateId
        });

        connection.query(
          `UPDATE companies SET company_organization_name = ?, template_id = ?, company_json = ? WHERE company_id = ?;`,
          [companyName, templateId, json, c.id],
          function (err, companies, fields) {
            if (!err) {
              console.log(`${c.inn} ${companyName}`.green);
            } else {
              console.error(`${c.inn} Ошибка обновления`.red);
            }
          }
        );
      } else {
        console.error(`${c.inn} ООО`.red);
      }
    })
  }
);
