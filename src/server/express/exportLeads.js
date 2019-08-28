const env = require('../../env.json');
const mysql = require('mysql-promise')();
const moment = require('moment');
const json2xls = require('json2xls');
const nodeZip = require('node-zip');
const fs = require('fs');
const path = require('path');

mysql.configure(env.mysql);

const TYPES = {
  10: "Свободный",
  13: "Утверждено",
  14: "Не интересный",
  24: "Дубликат",
  23: "Перезвонить",
  // 36: "Недозвон",
}

const REGIONS = [
  { name: "Воронеж", ids: [35] },
  { name: "Калуга", ids: [40] },
  { name: "Новосибирск", ids: [54] },
  { name: "Омск", ids: [55] },
  { name: "Санкт-Петербург", ids: [47, 78] },
  { name: "Саратов", ids: [64] },
  { name: "Томск", ids: [64] },
  { name: "Уфа", ids: [2] },
]

module.exports = (req, res) => {
  const previousWeek = moment().locale('ru').subtract(1, 'week');
  const startWeek = previousWeek.startOf('week').format("YYYY-MM-DD");
  const endWeek = previousWeek.endOf('week').subtract(2, 'day').format("YYYY-MM-DD");

  const getLeads = (regionsId, name) => {
    return mysql.query(`
      SELECT
        regions.region_name "Регион УНФС",
        company_inn "ИНН",
        cities.city_name "Город УНФС",
        company_phone "Телефон",
        company_date_create "Дата добавления компании в базу",
        company_person_name "Имя",
        company_person_surname "Фамилия",
        company_organization_name "Название организации",
        company_person_patronymic "Отчество"
      FROM companies c
      JOIN cities ON c.city_id = cities.city_id
      JOIN regions ON c.region_id = regions.region_id
      JOIN templates ON c.template_id = templates.template_id
      WHERE
        templates.channel_id = 1 AND
        c.type_id IN (${Object.keys(TYPES).join(", ")}) AND
        c.region_id IN (${regionsId.join(", ")}) AND
        company_date_create BETWEEN ? AND ?
      `,
      [startWeek, endWeek]
    ).spread(leads => {
      return { leads, name };
    }).catch(error => {
      throw error;
    });
  }

  Promise.all(REGIONS.map(r => {
    return getLeads(r.ids, r.name);
  })).then(leadsByRegion => {
    const zip = nodeZip();

    const datesString = `${moment(startWeek).format('DD.MM')} - ${moment(endWeek).format('DD.MM')}`;

    leadsByRegion.map((leads, key) => {
      console.log('l', leads.leads.length);
      leads.leads.length && zip.file(
        `${leads.name} ${datesString}.xlsx`,
        Buffer.from(json2xls(leads.leads), 'binary')
      );
    })
    const file = zip.generate({ base64:false, compression: 'DEFLATE' });
    res.set('Content-Type', 'application/zip')
    res.set('Content-Disposition', `attachment; filename=leads.zip`);
    res.set('Content-Length', file.length);
    res.end(file, 'binary');
  });
}
