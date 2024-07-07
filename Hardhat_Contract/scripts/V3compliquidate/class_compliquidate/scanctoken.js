const { getcontractinfo } = require('../../../nodetool/id-readcontracts.js');
const web3 = require('web3');
const mysql = require("mysql2");
const compinfo = require("../abiinfo/Comptroller.json");
const ctokeninfo = require("../abiinfo/CErc20Delegator.json");
const oracleinfo = require("../abiinfo/Linkoracle.json");
const secret = require("../../../../../zm_privateinfo/.secret.js");
const ethers = require("ethers");
var check_point = 0;
const { cl_fun } = require("./cl_fun.js")
class compliquidate extends cl_fun {
    constructor(info) {
        super()
        this.cl = this;
        this.cl.deal = {}
        let check = ["comp_add", "blocknumber", "url", "sqlinfo"];
        if (!check.every(key => key in info)) {
            throw "error info"
        }
        this.cl.info = info;
        this.cl.web3js = new web3((info.url + info.key));
        this.cl.comp = new this.cl.web3js.eth.Contract(compinfo.abi, info.comp_add)
        this.cl.poolinfo = info.sqlinfo;
        this.cl.pool = mysql.createPool(this.cl.poolinfo);

    }
    async scan() {

        await this.cl._scanctokens();
        console.log(
            "scanctoken once"
        );
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
        this._scanlog();
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
                    // this.cl.liquidate(
                    //     nowinfo.account,
                    //     m_deposit,
                    //     m_borrow
                    // )
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
    async liquidate(address, m_deposit, m_borrow) {
        console.log(address, m_deposit, m_borrow);
        return
        {//test
            let b_ctoken = this.cl.ctokens[m_borrow.symbol].ctoken;
            console.log("b_ctoken", b_ctoken.address);
            let b_token = new this.cl.web3js.eth.Contract(ctokeninfo.abi,
                await this.cl.oracle._getUnderlyingAddress(b_ctoken.address)
            )
            if (await b_token.allowance(address, b_ctoken.address)) {

            }
            await b_ctoken.liquidateBorrow(address, m_borrow.amount, this.cl.ctokens[m_deposit].info.address)
        }
        // let b_ctoken = this.cl.ctokens[m_borrow].ctoken;
        // await ctoken.liquidateBorrow(address, this.cl.ctokens[m_deposit].info.address)

    }
    async test(address) {
        let ctokens = this.cl.ctokens;
        let hash = await ethers.utils.keccak256(await ethers.utils.defaultAbiCoder.encode(["address", "uint"], [address, this.cl.info.storage]))
        console.log(
            await this.cl.web3js.eth.getStorageAt(ctokens["0xEC8FEa79026FfEd168cCf5C627c7f486D77b765F"].info.address, hash),
            await this.cl.web3js.eth.getStorageAt(ctokens["0xEC8FEa79026FfEd168cCf5C627c7f486D77b765F"].info.address, addrAdd(hash, 1)),
        );
    }

}

async function main() {
    var contractinfo = await getcontractinfo();
    let info = {
        // storage: 16,
        // comp_add: contractinfo["7156777"].Comptroller.address,
        // blocknumber: contractinfo["7156777"].Comptroller.blocknumber,
        // url: contractinfo["7156777"].Comptroller.network.url,

        storage: 17,
        comp_add: "0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B",
        blocknumber: 7710671,
        url: "https://eth-mainnet.g.alchemy.com/v2/",
        key: "bj9-ee__TlT6yb0EnceFhw0pFfPqglTt",
        oncescan: 2000,

        // storage: 16,
        // comp_add: "0xa86DD95c210dd186Fa7639F93E4177E97d057576",
        // blocknumber: 111012802,
        // url: "https://arb-mainnet.g.alchemy.com/v2/",
        // key: "bj9-ee__TlT6yb0EnceFhw0pFfPqglTt",
        // oncescan: 20000,

        // storage: 16,
        // comp_add: "0x60CF091cD3f50420d50fD7f707414d0DF4751C58",
        // blocknumber: 26050083,
        // url: "https://opt-mainnet.g.alchemy.com/v2/",
        // key: "JMXf8v9YewnKf_XC7tMigeXAFPS3GLj9",
        // oncescan: 200000,

        sqlinfo: secret.compliquidate.mysqlpool
    }
    let a = new compliquidate(info)
    await a.init()
    // await a._scanctoken("0x8cD6b19A07d754bF36AdEEE79EDF4F2134a8F571")
    // await a.scan();
    // await a.test("0x77112f18a91e171904c8d71f8be7fdfbf57f1af4")
    await a.scanaccount();
    // setTimeout(function () {
    //     setInterval(async () => {
    //         await a.scan();
    //     }, 500)
    // }, 0);
    // setTimeout(function () {
    //     setInterval(async () => {
    //         await a.update_ctoken();
    //     }, 1500)
    // }, 5);
    // setTimeout(function () {
    //     setInterval(async () => {
    //         await a.scanaccount();
    //     }, 500)
    // }, 2);
    // return
}
async function taskSyncscan(a) {
    await a.scan();// 扫块
}
main()


module.exports = {
    compliquidate
}


function addrAdd(_from, _num) {
    let b = ethers.BigNumber.from(_from).add(_num)
    return ethers.utils.hexValue(b);
}