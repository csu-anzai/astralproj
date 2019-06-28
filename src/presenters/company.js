// presenters Функция преобразования/форматирования объекта компании
const formatPhoneNumber = require('../libs/formatPhoneNumber.js');
const formatName = name => {
  if (typeof name != "string") return '';
  return name[0].toUpperCase() + name.slice(1).toLowerCase();
};

module.exports = c => ({
  ...c,
  fio: [ /* добавляем ФИО */
    c.companyPersonSurname,
    c.companyPersonName,
    c.companyPersonPatronymic
  ].map(formatName).join(" "),
  companyPersonSurname: formatName(c.companyPersonSurname),
  companyPersonName: formatName(c.companyPersonName),
  companyPersonPatronymic: formatName(c.companyPersonPatronymic),
  phone: formatPhoneNumber(c.companyPhone)
})