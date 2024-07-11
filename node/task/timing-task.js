const axios = require("axios");
const mysql = require("mysql2");
let sqlpool = mysql.createPool(global.mysqlpoolGlobal);
async function sqlcall(selSql, selSqlParams) {
    let pool = sqlpool;
    return new Promise(function (resolve, reject) {
        try {
            pool.query(selSql, selSqlParams, async function (err, result) {
                if (err) {
                    if (err.code === 'ER_CON_COUNT_ERROR') {
                        console.log("sql请求过多，等待1秒");
                        await new Promise(resolve => setTimeout(resolve, 1000));
                        resolve(await sqlcall(sqlStatements))
                        return;
                    } else {
                        throw err;
                    }
                }
                let dataString = JSON.stringify(result);
                let data = JSON.parse(dataString);
                resolve(data);

            });
        } catch (error) {
            console.log(error);
            reject(error)
        }
    });
}

exports.taskStart = async function taskStart() {
    await taskSyncpricescan()
    setTimeout(function () {
        setInterval(taskSyncpricescan, 1000 * 600);// task I,Synchronization levelnft event record,Do it every 10s
    }, 0);
}
async function taskSyncpricescan() {
    console.log("task I   (20s)  ========>  taskSyncpricescan ...");
    await pricescan();// 扫块
}

async function pricescan() {
    let dstAmount_1insh = await httpCall(
        "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
        "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22",
        "qOckYWrul8FjTaGBRQSz6UmgKcxqcYhW"
    );
    await wait(2000);
    let re_price = await httpCall(
        "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22",
        "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
        "qOckYWrul8FjTaGBRQSz6UmgKcxqcYhW"
    );

    let currentDate = new Date();
    let year = currentDate.getFullYear().toString();
    let month = (currentDate.getMonth() + 1).toString().padStart(2, '0');
    let day = currentDate.getDate().toString().padStart(2, '0');
    let hour = currentDate.getHours().toString().padStart(2, '0');
    let minute = currentDate.getMinutes().toString().padStart(2, '0');
    await sqlcall(
        `
            INSERT INTO priceinfo (pair, price, pricepoint, year, month, day, hour, minute,re_price,re_pricepoint)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?,?,?)
        `,
        [
            "wstETH/cbETH",
            dstAmount_1insh, (dstAmount_1insh / 10 ** 18).toString(),
            year, month, day, hour, minute,
            re_price, (re_price / 10 ** 18).toString()
        ]
    );


}

async function httpCall(src, dst, token) {
    const url = "https://api.1inch.dev/swap/v6.0/8453/quote";
    const config = {
        headers: {
            "Authorization": "Bearer " + token
        },
        params: {
            // "src": "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
            // "dst": "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22",
            "src": src,
            "dst": dst,
            "amount": "1000000000000000000"
        }
    };
    try {
        const response = await axios.get(url, config);
        return response.data.dstAmount;
    } catch (error) {
        console.error(error);
    }
}

async function wait(ms) {
    return new Promise(resolve => setTimeout(() => resolve(), ms));
}
