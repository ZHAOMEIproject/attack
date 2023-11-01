// npx hardhat run  scripts/tool/test.js  --network hardhat
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('./hh_log.js');
const { getcontractinfo } = require('./id-readcontracts');
const { WITHDRAW_loc_getsign } = require("./sign/loc_getsign");
var contractinfo = new Object();
async function main() {
    const { getcontractinfo } = require('./id-readcontracts');
    const { WITHDRAW_loc_getsign } = require("./sign/loc_getsign");
    var contractinfo = new Object();
    main()
    async function main() {
        contractinfo = await getcontractinfo();
        var chainid = '31337'
        var devinfo = contractinfo[chainid];
        var path = "m/44'/60'/0'/9/9";
        var mnemonic = config.networks.hardhat.accounts.mnemonic;
        var Mnemonic = ethers.HDNodeWallet.fromPhrase(mnemonic).mnemonic;
        const account = await ethers.HDNodeWallet.fromMnemonic(Mnemonic, path);
        let WITHDRAW_permit = await WITHDRAW_loc_getsign(
            devinfo.mainwithdrawV2,
            [
                "0xd7B74f2133C011110a7A38038fFF30bDc9ACe6d1",
                "1000",
                "1413336447911231489",
                "9999999999"
            ],
            account.privateKey
        )
        console.log(account.address);
        console.log(WITHDRAW_permit);
    }
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
function serializeBigInt(data) {
    return JSON.stringify(data, (_, value) =>
        typeof value === 'bigint'
            ? value.toString()
            : value
    );
}


async function decimal2big(token, value) {
    return BigInt(Math.floor(value * (10 ** Number(await token.decimals()))))
}
async function decimal2show(token, value) {
    return Math.floor(Number(value / (10n ** await token.decimals())))
}