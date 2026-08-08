const mariadb = require('mariadb');
const pool = mariadb.createPool({
  host: 'localhost',
  user: 'root',
  password: '',
  port: 3306,
  database: 'palm_oil_db',
  connectionLimit: 5
});

module.exports = pool;