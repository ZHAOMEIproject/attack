const oracleinfo = require("../abiinfo/Linkoracle.json");
const ctokeninfo = require("../abiinfo/CErc20Delegator.json");
const cethinfo = require("../abiinfo/CEther.json");
const ethers = require("ethers");
class cl_fun {
    constructor() {
        this["class"] = {
            "init": new init(this),
            "sql": new sql(this),
            "ctoken": new ctoken(this),
            "user": new user(this),
            "scan": new scan(this),
            "liquidate": new liquidate(this)
        }
    }
    async init() {
        await this.cl.class.init._init();
        await this.cl.class.init._initctokeninfo()
        this.cl.now_blockNumber = await this.cl.web3js.eth.getBlockNumber();
        console.log("init end");
    }
    _scanlog() {
        console.log(
            "_scanctoken:", Date.now(),
            "now_blockNumber:", this.cl.now_blockNumber, "key:", this.cl.info.key
        );

    }
}

class init {
    constructor(cl) {
        this.cl = cl;
    }
    // 初始化数据库
    async _init() {
        let tasks = [];
        if ((await this.cl.class.sql.sqlcall("SHOW TABLES like 'ctoken_scan'", null)).length == 0) {
            let selSql = "CREATE TABLE `ctoken_scan` (" +
                "  `name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
                "  `symbol` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
                "  `token` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
                "  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `collateralFactor` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
                "  `price` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
                "  `exchangeRate` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
                "  `borrowIndex` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL," +
                "  `blocknumber` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0'," +
                "  PRIMARY KEY (`address`)," +
                "  UNIQUE KEY `only` (`address`)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;"
            tasks.push([selSql])
        }
        if ((await this.cl.class.sql.sqlcall("SHOW TABLES like 'user'", null)).length == 0) {
            let selSql = "CREATE TABLE `user` (" +
                "  `account` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `liquidity` decimal(65,0) NOT NULL DEFAULT '0'," +
                "  `deposit` decimal(65,0) NOT NULL DEFAULT '0'," +
                "  `borrow` decimal(65,0) NOT NULL DEFAULT '0'," +
                "  `Health_Factor` decimal(65,0) DEFAULT '0'," +
                "  `original_deposit` decimal(65,0) DEFAULT '0'," +
                "  `update_blocknumber` bigint NOT NULL DEFAULT '0'," +
                "  `last_update_time` bigint DEFAULT '0'," +
                "  PRIMARY KEY (`account`)," +
                "  KEY `time` (`last_update_time`) USING BTREE" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;"
            tasks.push([selSql])
        }
        if ((await this.cl.class.sql.sqlcall("SHOW TABLES like 'deposit'", null)).length == 0) {
            let selSql = "CREATE TABLE `deposit` (" +
                "  `account` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `symbol` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `amount` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0'," +
                // "  `update_blocknumber` bigint NOT NULL DEFAULT '0'," +
                "  UNIQUE KEY `only` (`account`,`address`)," +
                "  KEY `number` (`amount`) USING BTREE" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;"
            tasks.push([selSql])
        }
        if ((await this.cl.class.sql.sqlcall("SHOW TABLES like 'borrow'", null)).length == 0) {
            let selSql = "CREATE TABLE `borrow` (" +
                "  `account` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `symbol` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL," +
                "  `amount` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0'," +
                // "  `update_blocknumber` bigint NOT NULL DEFAULT '0'," +
                "  UNIQUE KEY `only` (`account`,`address`)," +
                "  KEY `number` (`amount`) USING BTREE" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;"
            tasks.push([selSql])
        }
        await this.cl.class.sql.sqlbeginTransaction(tasks);
    }

    // 初始化ctoken
    async _initctokeninfo() {
        let comp = this.cl.comp;
        let [ctoken_adds, priceOracle] = await Promise.all([
            comp.methods.getAllMarkets().call(),
            comp.methods.oracle().call()
        ])
        this.cl.oracle = new this.cl.web3js.eth.Contract(oracleinfo.abi, priceOracle)
        let ctokens = {};
        this.cl.ctokens = ctokens
        for (let i in ctoken_adds) {
            try {
                let address = ctoken_adds[i]
                let ctoken = new this.cl.web3js.eth.Contract(ctokeninfo.abi, address)
                let [
                    name,
                    symbol,
                    collateralFactor,
                    price,
                    exchangeRate,
                    borrowIndex,
                ] = await Promise.all([
                    ctoken.methods.name().call(),
                    ctoken.methods.symbol().call(),
                    comp.methods.markets(address).call(),
                    this.cl.oracle.methods.getUnderlyingPrice(address).call(),
                    ctoken.methods.exchangeRateStored().call(),
                    ctoken.methods.borrowIndex().call(),
                ])
                let token = "ETH";
                try {
                    token = await ctoken.methods.underlying().call()
                } catch (error) {

                }
                collateralFactor = collateralFactor.collateralFactorMantissa
                ctokens[address] = {
                    info: {
                        name,
                        symbol,
                        address: address,
                        collateralFactor,
                        price,
                        exchangeRate,
                        borrowIndex,
                        token
                    },
                    ctoken,
                }
                let blocknumber = await this.cl.class.sql.sqlcall('select blocknumber from ctoken_scan where address=?', address);

                if (blocknumber[0]) {
                    this.cl.ctokens[address]["blocknumber"] = blocknumber[0].blocknumber;
                    this.cl.ctokens[address].info["blocknumber"] = blocknumber[0].blocknumber;
                } else {
                    this.cl.ctokens[address]["blocknumber"] = this.cl.info.blocknumber
                    this.cl.ctokens[address].info["blocknumber"] = this.cl.info.blocknumber
                }
                let creatnumber = await getaddressfirstblocknumber(address)
                if (creatnumber > this.cl.ctokens[address]["blocknumber"]) {
                    this.cl.ctokens[address]["blocknumber"] = creatnumber;
                    this.cl.ctokens[address].info["blocknumber"] = creatnumber;
                }
            } catch (error) {

            }

        }
        await this.cl.class.ctoken._updatectokeninfo();
    }
}
class sql {
    constructor(cl) {
        this.cl = cl;
    }
    async sqlcall(selSql, selSqlParams) {
        let pool = this.cl.pool;
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
    async sqlbeginTransaction(sqlStatements) {
        let pool = this.cl.pool;
        return new Promise(async function (resolve, reject) {
            try {
                pool.getConnection(async function (err, connection) {
                    if (err) {
                        if (err.code === 'ER_CON_COUNT_ERROR') {
                            console.log("sql请求过多，等待1秒");
                            await new Promise(resolve => setTimeout(resolve, 1000));
                            resolve(await beginTransaction(sqlStatements))
                            return;
                        } else {
                            throw err;
                        }
                    }
                    connection.beginTransaction(function (err) {
                        if (err) throw err;
                        let funcAry = sqlStatements.map((sql, index) => {
                            return new Promise((sqlResolve, sqlReject) => {
                                // const data = params[index];
                                connection.query(sql[0], sql[1], (sqlErr, result) => {
                                    if (sqlErr) {
                                        return sqlReject(sqlErr);
                                    }
                                    sqlResolve(result);
                                });
                            });
                        });
                        Promise.all(funcAry)
                            .then((arrResult) => {
                                // 若每个sql语句都执行成功了 才会走到这里 在这里需要提交事务，前面的sql执行才会生效
                                // 提交事务
                                connection.commit(function (commitErr, info) {
                                    if (commitErr) {
                                        // 提交事务失败了
                                        console.log("提交事务失败:" + commitErr);
                                        // 事务回滚，之前运行的sql语句不生效
                                        connection.rollback(function (err) {
                                            if (err) console.log("回滚失败：" + err);
                                            connection.release();
                                        });
                                        // 返回promise失败状态
                                        return reject(commitErr);
                                    }

                                    connection.release();
                                    // 事务成功 返回 每个sql运行的结果 是个数组结构
                                    resolve(arrResult);
                                });
                            })
                            .catch((error) => {
                                // 多条sql语句执行中 其中有一条报错 直接回滚
                                connection.rollback(function () {
                                    console.log("sql运行失败： " + error);
                                    connection.release();
                                    reject(error);
                                });
                            });
                    });
                });
            } catch (error) {
                console.log(error);
                reject(error)
            }
        });
    }

}
class ctoken {
    constructor(cl) {
        this.cl = cl;
    }
    async _updatectokeninfo() {
        let ctokens = this.cl.ctokens;
        let tasks = []
        for (let address in ctokens) {
            tasks.push(this._sqladdctoken(address))
        }
        await Promise.all(tasks)
    }
    async _sqladdctoken(address) {
        let token = this.cl.ctokens[address];
        let tasks = []
        tasks.push(this.cl.class.sql.sqlcall('REPLACE INTO ctoken_scan SET ?', token.info))
        await Promise.all(tasks)
    }

}
class user {
    constructor(cl) {
        this.cl = cl;
    }
    async _updateuserallinfo(address) {
        if (!this.cl.now_blockNumber) {
            this.cl.now_blockNumber = await this.cl.web3js.eth.getBlockNumber();
        }
        let ctokens = this.cl.ctokens;
        // let user = {
        //     address,
        //     "deposit": 0,
        //     "borrow": 0,
        //     "liquidity": 0,
        //     "Health_Factor": 0,
        //     "last_update_time": 0,
        // }
        let userupdatesql = []
        let [total_deposit, total_borrow, original_deposit] = [0, 0, 0];
        let m_deposit = {
            address: "",
            symbol: "",
            amount: 0
        }
        let m_borrow = {
            address: "",
            symbol: "",
            amount: 0
        }
        let hash = await ethers.utils.keccak256(await ethers.utils.defaultAbiCoder.encode(["address", "uint"], [address, this.cl.info.storage]))
        for (let i in ctokens) {
            let borrow = 0
            let checkMembership = await this.cl.comp.methods.checkMembership(address, ctokens[i].info.address).call();
            if (!checkMembership) {
                continue
            }
            let [
                borrowBalance,
                borrowIndex,
                balance
            ] = await Promise.all([
                this.cl.web3js.eth.getStorageAt(ctokens[i].info.address, hash),
                this.cl.web3js.eth.getStorageAt(ctokens[i].info.address, addrAdd(hash, 1)),
                ctokens[i].ctoken.methods.balanceOf(address).call(),
            ])
            borrowBalance = BigInt(borrowBalance);
            borrowIndex = BigInt(borrowIndex);
            if (balance != 0) {
                userupdatesql.push([`
                    REPLACE INTO deposit SET 
                    account = '${address}',
                    address = '${i}',
                    symbol = '${ctokens[i].info.symbol}',
                    amount = ${balance}
                `])
            }
            if (borrowIndex) {
                borrow = String(borrowBalance * BigInt(10 ** 18) / borrowIndex);
            }
            let ndeposit = (
                balance *
                ctokens[i].info.exchangeRate / 10 ** 18 *
                ctokens[i].info.collateralFactor / 10 ** 18 *
                ctokens[i].info.price / 10 ** 18
            )
            original_deposit += (
                balance *
                ctokens[i].info.exchangeRate / 10 ** 18 *
                ctokens[i].info.price / 10 ** 18
            )
            total_deposit += ndeposit
            let nborrow = (
                borrow *
                ctokens[i].info.borrowIndex / 10 ** 18 *
                ctokens[i].info.price / 10 ** 18
            )
            total_borrow += nborrow
            if (ndeposit >= m_deposit.amount) {
                m_deposit = {
                    address: i,
                    symbol: ctokens[i].info.symbol,
                    amount: balance *
                        ctokens[i].info.exchangeRate / 10 ** 18
                }
            }
            if (nborrow > m_borrow.amount) {
                m_borrow = {
                    address: i,
                    symbol: ctokens[i].info.symbol,
                    amount: borrow *
                        ctokens[i].info.borrowIndex / 10 ** 18
                }
            }
            if (borrow != 0) {
                userupdatesql.push([`
                    REPLACE INTO borrow SET 
                    account = '${address}',
                    address = '${i}',
                    symbol = '${ctokens[i].info.symbol}',
                    amount = ${borrow}
                `])
            }
        }
        let liquidity = total_deposit - total_borrow;
        if (liquidity < 0) {
            console.log(
                "user:", address, "liquidity:", liquidity, "\n",
                m_deposit.address, m_borrow.address, "\n",
                m_deposit.symbol, m_deposit.amount, m_borrow.symbol, m_borrow.amount,
            );
            this.cl.class.liquidate.liquidate(
                address,
                m_deposit,
                m_borrow
            )
        }
        let Health_Factor = 10 ** 9;
        if (total_borrow != 0) {
            Health_Factor = total_deposit * 10 ** 8 / total_borrow;
            if (Health_Factor > 10 ** 9) {
                Health_Factor = 10 ** 9;
            }
        }
        userupdatesql.push([`
            REPLACE INTO user SET 
                account = '${address}',
                liquidity = '${liquidity}',
                deposit = '${total_deposit}',
                original_deposit = '${original_deposit}',
                borrow = '${total_borrow}',
                Health_Factor = '${Health_Factor}',
                update_blocknumber = '${this.cl.now_blockNumber}',
                last_update_time = UNIX_TIMESTAMP()
        `]);
        await this.cl.class.sql.sqlbeginTransaction(userupdatesql)
    }
    async justupdateuserallinfo(address) {
        if (!this.cl.now_blockNumber) {
            this.cl.now_blockNumber = await this.cl.web3js.eth.getBlockNumber();
        }
        let ctokens = this.cl.ctokens;
        // let user = {
        //     address,
        //     "deposit": 0,
        //     "borrow": 0,
        //     "liquidity": 0,
        //     "Health_Factor": 0,
        //     "last_update_time": 0,
        // }
        let userupdatesql = []
        let [total_deposit, total_borrow, original_deposit] = [0, 0, 0];
        let m_deposit = {
            address: "",
            symbol: "",
            amount: 0
        }
        let m_borrow = {
            address: "",
            symbol: "",
            amount: 0
        }
        let hash = await ethers.utils.keccak256(await ethers.utils.defaultAbiCoder.encode(["address", "uint"], [address, this.cl.info.storage]))
        for (let i in ctokens) {
            let borrow = 0
            let checkMembership = await this.cl.comp.methods.checkMembership(address, ctokens[i].info.address).call();
            if (!checkMembership) {
                continue
            }
            let [
                borrowBalance,
                borrowIndex,
                balance
            ] = await Promise.all([
                this.cl.web3js.eth.getStorageAt(ctokens[i].info.address, hash),
                this.cl.web3js.eth.getStorageAt(ctokens[i].info.address, addrAdd(hash, 1)),
                ctokens[i].ctoken.methods.balanceOf(address).call(),
            ])
            borrowBalance = BigInt(borrowBalance);
            borrowIndex = BigInt(borrowIndex);
            if (balance != 0) {
                userupdatesql.push([`
                    REPLACE INTO deposit SET 
                    account = '${address}',
                    address = '${i}',
                    symbol = '${ctokens[i].info.symbol}',
                    amount = ${balance}
                `])
            }
            if (borrowIndex) {
                borrow = String(borrowBalance * BigInt(10 ** 18) / borrowIndex);
            }
            let ndeposit = (
                balance *
                ctokens[i].info.exchangeRate / 10 ** 18 *
                ctokens[i].info.collateralFactor / 10 ** 18 *
                ctokens[i].info.price / 10 ** 18
            )
            original_deposit += (
                balance *
                ctokens[i].info.exchangeRate / 10 ** 18 *
                ctokens[i].info.price / 10 ** 18
            )
            total_deposit += ndeposit
            let nborrow = (
                borrow *
                ctokens[i].info.borrowIndex / 10 ** 18 *
                ctokens[i].info.price / 10 ** 18
            )
            total_borrow += nborrow
            if (ndeposit >= m_deposit.amount) {
                m_deposit = {
                    address: i,
                    symbol: ctokens[i].info.symbol,
                    amount: balance *
                        ctokens[i].info.exchangeRate / 10 ** 18
                }
            }
            if (nborrow > m_borrow.amount) {
                m_borrow = {
                    address: i,
                    symbol: ctokens[i].info.symbol,
                    amount: borrow *
                        ctokens[i].info.borrowIndex / 10 ** 18
                }
            }
            if (borrow != 0) {
                userupdatesql.push([`
                    REPLACE INTO borrow SET 
                    account = '${address}',
                    address = '${i}',
                    symbol = '${ctokens[i].info.symbol}',
                    amount = ${borrow}
                `])
            }
        }
        let liquidity = total_deposit - total_borrow;
        let Health_Factor = 10 ** 9;
        if (total_borrow != 0) {
            Health_Factor = total_deposit * 10 ** 8 / total_borrow;
            if (Health_Factor > 10 ** 9) {
                Health_Factor = 10 ** 9;
            }
        }
        userupdatesql.push([`
            REPLACE INTO user SET 
                account = '${address}',
                liquidity = '${liquidity}',
                deposit = '${total_deposit}',
                original_deposit = '${original_deposit}',
                borrow = '${total_borrow}',
                Health_Factor = '${Health_Factor}',
                update_blocknumber = '${this.cl.now_blockNumber}',
                last_update_time = UNIX_TIMESTAMP()
        `]);
        await this.cl.class.sql.sqlbeginTransaction(userupdatesql)
    }
    async _event2updateuser(address, event_blocknumber) {
        if (!this.cl.deal[address]) {
            this.cl.deal[address] = {}
            this.cl.deal[address]["last_update_blocknumber"] = 0
        }
        if (this.cl.deal[address].last_update_blocknumber >= event_blocknumber) { return }
        this.cl.deal[address].last_update_blocknumber = this.cl.now_blockNumber;
        await this.cl.class.sql.sqlcall(`
            INSERT INTO user (account) VALUES (?)
            ON DUPLICATE KEY UPDATE account = VALUES(account);
        `, address)
        let last_update_blocknumber = (await this.cl.class.sql.sqlcall("select update_blocknumber from user where account=?", address))[0].update_blocknumber;
        if (last_update_blocknumber >= event_blocknumber) { return }
        await this._updateuserallinfo(address);
    }
}
class scan {
    constructor(cl) {
        this.cl = cl;
    }
    async _scanctokens() {
        let ctokens = this.cl.ctokens;
        let web3js = this.cl.web3js;
        let now_blockNumber = await web3js.eth.getBlockNumber();
        let now_blockinfo = await web3js.eth.getBlock(now_blockNumber);
        if (now_blockinfo.timestamp > (new Date() / 1000 - 60)) {
            now_blockNumber -= 4;
        }
        this.cl.now_blockNumber = now_blockNumber;
        console.clear();
        console.log(
            "_scanctoken:", Date.now(),
            "now_blockNumber:", now_blockNumber
        );
        for (let i in ctokens) {
            await this._scanctoken(i);
        }
        return
    }
    async _scanctoken(i) {
        let ctokens = this.cl.ctokens;
        let now_blockNumber = this.cl.now_blockNumber;
        let [
            fromBlock,
            toBlock
        ] = [
                // 0,
                Number(ctokens[i].blocknumber),
                Number(ctokens[i].blocknumber) + parseInt(this.cl.info.oncescan),
            ]
        {//扫描区块优化
            if (toBlock > now_blockNumber) {
                toBlock = now_blockNumber; // update toBlock
            }
            if (fromBlock >= toBlock) {
                return
            }
        }
        let eventinfo;
        try {
            eventinfo = await ctokens[i].ctoken.getPastEvents('allEvents', {
                fromBlock: fromBlock,
                toBlock: now_blockNumber,
            });
            toBlock = now_blockNumber;
        } catch (error) {
            eventinfo = await ctokens[i].ctoken.getPastEvents('allEvents', {
                fromBlock: fromBlock,
                toBlock: toBlock,
            });
        }
        for (let k in eventinfo) {
            switch (eventinfo[k].event) {
                case "Transfer":
                    await this.cl.class.user._event2updateuser(
                        eventinfo[k].returnValues[0], eventinfo[k].blockNumber
                    )
                    await this.cl.class.user._event2updateuser(
                        eventinfo[k].returnValues[1], eventinfo[k].blockNumber
                    )
                    break;
                case "Borrow":
                    await this.cl.class.user._event2updateuser(eventinfo[k].returnValues[0], eventinfo[k].blockNumber)
                    break;
                case "RepayBorrow":
                    await this.cl.class.user._event2updateuser(eventinfo[k].returnValues[1], eventinfo[k].blockNumber)
                    break;
                default:
                    break;
            }
        }
        ctokens[i].blocknumber = toBlock;
        if (eventinfo.length != 0) {
            ctokens[i].blocknumber = eventinfo[eventinfo.length - 1].blockNumber;
        }
        if (toBlock > ctokens[i].blocknumber) {
            ctokens[i].blocknumber = toBlock;
        }
        console.log(
            i, ctokens[i].info.symbol, "needtimes:", (now_blockNumber - ctokens[i].blocknumber) / this.cl.info.oncescan,
            "\nf:", fromBlock, "t:", toBlock, "n:", now_blockNumber, "e:", ctokens[i].blocknumber
        );
        await this.cl.class.sql.sqlcall(`update ctoken_scan set blocknumber = ${ctokens[i].blocknumber} where address='${i}'`);
        if (ctokens[i].blocknumber + parseInt(this.cl.info.oncescan) < now_blockNumber) {
            await this._scanctoken(i)
        }
    }

    async scanaccount() {
        console.log(
            "scanaccount:", this.cl.now_blockNumber
        );

        let useramount = (await this.cl.class.sql.sqlcall(`
            SELECT COUNT(*) as useramount FROM user where deposit!=0 AND borrow!=0;
        `))[0]["useramount"];
        let onece = 1000;
        let times = useramount / onece;
        let ctokens = this.cl.ctokens
        for (let j = 0; j < times; j++) {
            console.log(j);
            let sql = `
                SELECT * FROM
                    user where deposit!=0 AND borrow!=0 
                ORDER BY 
                    last_update_time ASC
                LIMIT 
                    1000;
            `
            let accounts = await this.cl.class.sql.sqlcall(sql);
            for (let i in accounts) {
                let nowinfo = accounts[i]
                let borrows = await this.cl.class.sql.sqlcall(`
                    SELECT * FROM
                        borrow
                    WHERE account =? and amount != "0"
                `, nowinfo.account);
                let deposits = await this.cl.class.sql.sqlcall(`
                    SELECT * FROM
                        deposit
                    WHERE account =? and amount != "0"
                `, nowinfo.account);
                let [total_deposit, total_borrow, original_deposit] = [0, 0, 0];
                let m_deposit = {
                    address: "",
                    symbol: "",
                    amount: 0
                }
                let m_borrow = {
                    address: "",
                    symbol: "",
                    amount: 0
                }
                for (let j in deposits) {
                    let ndeposit = (
                        Number(deposits[j].amount) *
                        ctokens[deposits[j].address].info.exchangeRate / 10 ** 18 *
                        ctokens[deposits[j].address].info.collateralFactor / 10 ** 18 *
                        ctokens[deposits[j].address].info.price / 10 ** 18
                    )
                    original_deposit += (
                        Number(deposits[j].amount) *
                        ctokens[deposits[j].address].info.exchangeRate / 10 ** 18 *
                        ctokens[deposits[j].address].info.price / 10 ** 18
                    )
                    total_deposit += ndeposit
                    if (ndeposit >= m_deposit.amount) {
                        m_deposit = {
                            address: deposits[j].address,
                            symbol: ctokens[deposits[j].address].info.symbol,
                            amount: Number(deposits[j].amount) *
                                ctokens[deposits[j].address].info.exchangeRate / 10 ** 18
                        }
                    }
                }
                for (let j in borrows) {
                    let nborrow = (
                        Number(borrows[j].amount) *
                        ctokens[borrows[j].address].info.borrowIndex / 10 ** 18 *
                        ctokens[borrows[j].address].info.price / 10 ** 18
                    )
                    total_borrow += nborrow
                    if (nborrow > m_borrow.amount) {
                        m_borrow = {
                            address: borrows[j].address,
                            symbol: ctokens[borrows[j].address].info.symbol,
                            amount: Number(borrows[j].amount) *
                                ctokens[borrows[j].address].info.borrowIndex / 10 ** 18
                        }
                    }
                }
                let liquidity = total_deposit - total_borrow;
                if (liquidity < 0) {
                    console.log(
                        "user:", nowinfo.account, "liquidity:", liquidity, "\n",
                        m_deposit.address, m_borrow.address, "\n",
                        m_deposit.symbol, m_deposit.amount, m_borrow.symbol, m_borrow.amount,
                    );
                    this.cl.class.liquidate.liquidate(
                        nowinfo.account,
                        m_deposit,
                        m_borrow
                    )
                }
                let Health_Factor = 10 ** 9;
                if (total_borrow != 0) {
                    Health_Factor = total_deposit * 10 ** 8 / total_borrow;
                    if (Health_Factor > 10 ** 9) {
                        Health_Factor = 10 ** 9;
                    }
                }
                await this.cl.class.sql.sqlcall(`
                    REPLACE INTO user SET 
                        account = '${nowinfo.account}',
                        liquidity = '${liquidity}',
                        deposit = '${total_deposit}',
                        original_deposit = '${original_deposit}',
                        borrow = '${total_borrow}',
                        Health_Factor = '${Health_Factor}',
                        update_blocknumber = '${this.cl.now_blockNumber}',
                        last_update_time = UNIX_TIMESTAMP()
                `);
            }
        }
        console.log("scanaccount end");
    }

}
class liquidate {
    constructor(cl) {
        this.cl = cl;
    }
    // async liquidatebyaccount(account) {

    // }
    async liquidate(address, m_deposit, m_borrow) {
        await this.cl.class.user.justupdateuserallinfo(address);
        // console.log(address, m_deposit, m_borrow);
        // return
        try {
            {//test
                this.cl.web3js.eth.accounts.wallet.add('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80');
                this.cl.web3js.eth.defaultAccount = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
                if (this.cl.ctokens[m_borrow.address].info.token == "ETH") {
                    let e_b_ctoken = new this.cl.web3js.eth.Contract(cethinfo.abi, address)
                    await e_b_ctoken.methods.liquidateBorrow(address, m_deposit.address).send({
                        from: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
                        value: Math.floor(m_borrow.amount / 3)
                    });
                } else {
                    let b_ctoken = this.cl.ctokens[m_borrow.address].ctoken;
                    let b_token = new this.cl.web3js.eth.Contract(ctokeninfo.abi,
                        await this.cl.oracle.methods._getUnderlyingAddress(m_borrow.address).call()
                    )
                    if (await b_token.methods.allowance(address, m_borrow.address).call() < (await b_token.methods.totalSupply().call() / 2)) {
                        await b_token.methods.approve(m_borrow.address, await b_token.methods.totalSupply().call()
                        ).send({
                            from: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
                            gasLimit: "30000000"
                        });
                    }
                    await b_ctoken.methods.liquidateBorrow(address, Math.floor(m_borrow.amount / 3), m_deposit.address).send({
                        from: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
                        gasLimit: "30000000"
                    });
                }
            }
        } catch (error) {
            console.log(error);
        }
        await this.cl.class.user.justupdateuserallinfo(address);
    }


}


module.exports = {
    cl_fun
}

function addrAdd(_from, _num) {
    let b = ethers.BigNumber.from(_from).add(_num)
    return ethers.utils.hexValue(b);
}

async function getaddressfirstblocknumber(address) {
    // let scaninfo = await ScanApi("https://api.etherscan.io/api?module=logs&action=getLogs&fromBlock=0&page=1&offset=1"
    //     + "&apikey=NSYDK2DA22ZKUCJXKQ6NHR1FY4ZPJM8YP8&address="
    //     + address
    // );

    // let scaninfo = await ScanApi("https://api.arbiscan.io/api?module=logs&action=getLogs&fromBlock=0&page=1&offset=1"
    //     + "&apikey=1J2BP6W11Q2WCTA5J3AFGVARX98DAXIN8I&address="
    //     + address
    // );

    // let scaninfo = await ScanApi("https://api-optimistic.etherscan.io/api?module=logs&action=getLogs&fromBlock=0&page=1&offset=1"
    //     + "&apikey=1RY54Z4TVEKUQEQPZ791VZYAQYVVE65J9E&address="
    //     + address
    // );
    // let scaninfo = await ScanApi("https://vn.egoistmusic.top/api?module=logs&action=getLogs&fromBlock=0&toBlock=latest&page=1&offset=1"
    //     + "&apikey=1RY54Z4TVEKUQEQPZ791VZYAQYVVE65J9E&address="
    //     + address
    // );

    let scaninfo = [{ blockNumber: 0 }]



    return Number(scaninfo[0].blockNumber)
}
const request = require("request");
function ScanApi(url) {
    return new Promise(function (resolve, reject) {
        request({
            timeout: 10000,    // Set timeout
            method: 'GET',     // Set method
            url: url
        }, async function (error, response, body) {
            if (!error && response.statusCode == 200) {
                let json = JSON.parse(body);
                resolve(json.result);
            } else {
                console.log("message --> get api event contract fail.");
                global.zwjerror = true;
                resolve();
            }
        })
    })
}