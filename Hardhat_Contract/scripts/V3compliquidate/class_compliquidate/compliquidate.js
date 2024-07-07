const { getcontractinfo } = require('../../../nodetool/id-readcontracts.js');
const web3 = require('web3');
const mysql = require("mysql2");
const compinfo = require("../abiinfo/Comet.json");
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
    async test(address) {
        let ctokens = this.cl.ctokens;
        let hash = await ethers.utils.keccak256(await ethers.utils.defaultAbiCoder.encode(["address", "uint"], [address, this.cl.info.storage]))
        console.log(
            await this.cl.web3js.eth.getStorageAt(ctokens["0xEC8FEa79026FfEd168cCf5C627c7f486D77b765F"].info.address, hash),
            await this.cl.web3js.eth.getStorageAt(ctokens["0xEC8FEa79026FfEd168cCf5C627c7f486D77b765F"].info.address, addrAdd(hash, 1)),
        );
    }
    async scan() {
        await this.cl.class.scan._scanctokens();
        console.log(
            "scanctoken once"
        );
    }
    async update_ctoken() {
        console.log(
            "update_ctoken"
        );

        await this.cl.class.ctoken._updatectokeninfo();
    }
    async scanaccount() {
        await this.cl.class.scan.scanaccount();
    }
}

async function main() {
    var contractinfo = await getcontractinfo();
    let info = {
        // storage: 16,
        // comp_add: contractinfo["31337"].Comptroller.address,
        // blocknumber: contractinfo["31337"].Comptroller.blocknumber,
        // url: contractinfo["31337"].Comptroller.network.url,
        // key: "",
        // oncescan: 200000,

        storage: 16,
        comp_add: "0x1E9C6f3e8c0169EFe78Ae9D354bF69d2aE83D459",
        blocknumber: 0,
        url: secret.hardhatset.networks.base.url,
        key: "",
        oncescan: 200000,

        sqlinfo: secret.compliquidate.mysqlpool
    }
    let a = new compliquidate(info)
    await a.init()
    // await a._scanctoken("0x8cD6b19A07d754bF36AdEEE79EDF4F2134a8F571")
    await a.scan();
    await a.scanaccount();
    setTimeout(function () {
        setInterval(async () => {
            await a.scan();
        }, 5 * 1000)
    }, 0);
    setTimeout(function () {
        setInterval(async () => {
            await a.update_ctoken();
        }, 10 * 1000)
    }, 1 * 1000);
    setTimeout(function () {
        setInterval(async () => {
            await a.scanaccount();
        }, 10 * 1000)
    }, 1 * 1000);
    return
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