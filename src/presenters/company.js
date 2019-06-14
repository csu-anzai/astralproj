// presenters Функция преобразования/форматирования объекта компании
module.exports = c => ({
  ...c,
  fio: [ /* добавляем ФИО */
    c.companyPersonSurname,
    c.companyPersonName,
    c.companyPersonPatronymic
  ].map(name => (
    name[0].toUpperCase() + name.slice(1).toLowerCase()
  )).join(" ")
})