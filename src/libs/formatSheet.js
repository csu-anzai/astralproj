function formatHeader(header) {
  const keys = {
    surname: 'Фамилия',
    name: 'Имя',
    patronymic: 'Отчество',
    inn: 'ИНН',
    ogrn: 'ОГРН',
    ogrnDate: 'Дата присвоения ОГРН',
    address: 'Адрес',
    phone: 'Тел',
    email: 'mail'
  };

  return Object.keys(keys).filter(
    k => header.toLowerCase()
    .includes(keys[k].toLowerCase())
  )[0] || header;
}


module.exports = (workbook) => {
  let result;
  var sheet_name_list = workbook.SheetNames;
  sheet_name_list.forEach(function(y) {
      var worksheet = workbook.Sheets[y];
      var headers = {};
      var data = [];
      for(z in worksheet) {
          if(z[0] === '!') continue;
          var tt = 0;
          for (var i = 0; i < z.length; i++) {
              if (!isNaN(z[i])) {
                  tt = i;
                  break;
              }
          };
          var col = z.substring(0,tt);
          var row = parseInt(z.substring(tt));
          var value = worksheet[z].v;

          if(row == 1 && value) {
              headers[col] = formatHeader(value);
              continue;
          }

          if(!data[row]) data[row]={};
          data[row][headers[col]] = value;
      }
      data.shift();
      data.shift();

      result = data;
  });

  return result;
}
