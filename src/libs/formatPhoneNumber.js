const phone  = require('phone');

module.exports = (p) => {
  if (!p) return false;

  const phones = p.split(/[\s,;#]+/).map( p => {
    if(p.length >= 20 && p.length % 2 == 0) {
      return p.match(RegExp(".{1," + p.length/2 + "}", "g")).map(p => {
        return phone(p, "RUS")[0];
      }).filter(p => p)[0];
    }
    return phone(p, "RUS")[0];
  }).filter(p => p);
  return phones.length ? phones[0] : ( phone(p, "RUS")[0] || p);
}