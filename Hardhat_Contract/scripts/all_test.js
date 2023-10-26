// npx hardhat run scripts/all_test.js --network dev
// npx hardhat run scripts/all_test.js --network hardhat
// npx hardhat run scripts/all_test.js --network zhaomei
// npx hardhat run scripts/all_test.js --network mzhaomei
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('./tool/hh_log.js');
const { getcontractinfo } = require('./tool/id-readcontracts');
const { WITHDRAW_loc_getsign } = require("./tool/sign/loc_getsign");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();


    let Artifact = await artifacts.readArtifact("Qore");
    var Qore = new ethers.Contract(
        "0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48",
        Artifact.abi,
        owner
    );
    console.log(await Qore.allMarkets());





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