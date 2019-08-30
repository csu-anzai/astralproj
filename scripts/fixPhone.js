const request = require('request');
const mysql = require('mysql');
const colors = require('colors');

const connection = mysql.createConnection(require('../src/env.json').mysql);
connection.connect();

connection.query(`
  SELECT
    company_id id,
    company_inn inn,
    company_phone phone
  FROM
    companies
  WHERE
    company_date_create BETWEEN "2019-08-29" AND "2019-08-30"`,
  (err, companies, fields) => {
    companies.map(c => {
      connection.query(
        `UPDATE companies SET company_inn = ?, company_phone = ? WHERE company_id = ?`,
        [c.phone, c.inn, c.id],
        (err, r, fields) => {
          if (err) {
            if (err.code == "ER_DUP_ENTRY") {
              console.log(c.phone, c.inn, c.id, "Уже существует".red);
              connection.query(
                `DELETE FROM companies WHERE company_id = ?`,
                [c.id],
                (err, r, fields) => {
                  if (err) {
                    console.log(c.phone, c.inn, c.id, "Ошибка удаления".red);
                  } else {
                    console.log(c.phone, c.inn, c.id, "Лид удален".yellow);
                  }
                }
              );
            } else {
              console.log(c.phone, c.inn, c.id, "Неизвестная ошибка".red, err.code);
            }
          } else {
            console.log(c.phone, c.inn, c.id, "Лид исправлен".green);
          }
        }
      )
    })
  }
);
