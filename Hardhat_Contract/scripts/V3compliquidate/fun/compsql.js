const { sqlcall, beginTransaction } = require('../../../nodetool/sqlconnection');

async function checkcompdatabase() {
    let name = "comp"
    let selSql = "SHOW DATABASES LIKE ?";
    if ((await sqlcall(selSql, name)).length == 0) {
        selSql = "create database " + name;
        await sqlcall(selSql, name)
    }
    global.mysqlpoolGlobal.database = name;

    // 查/建表
    selSql = "SHOW TABLES like 'dictionary_value'";
    if ((await sqlcall(selSql, null)).length == 0) {
        selSql =
            "CREATE TABLE `ctoken` (" +
            "  `name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
            "  `address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
            "  `collateralFactor` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
            "  `price` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
            "  `net_worth` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;"
        await sqlcall(selSql, null);
    }
}
