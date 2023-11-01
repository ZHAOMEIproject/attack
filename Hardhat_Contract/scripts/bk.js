// npx hardhat run scripts/all_test.js --network dev
// npx hardhat run scripts/all_test.js --network hardhat
// npx hardhat run scripts/all_test.js --network zhaomei
// npx hardhat run scripts/all_test.js --network mzhaomei
const hre = require("hardhat");
const {
    writer_info, writer_info_all, writer_info_all_proxy
} = require('./tool/hh_log.js');
const { getcontractinfo } = require('./tool/id-readcontracts.js');
const { WITHDRAW_loc_getsign } = require("./tool/sign/loc_getsign.js");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();


    let QoreArtifact = await artifacts.readArtifact("Qore");
    var Qore = new ethers.Contract(
        "0xF70314eb9c7Fe7D88E6af5aa7F898b3A162dcd48",
        QoreArtifact.abi,
        owner
    );
    // let Markets = await Qore.allMarkets()
    // await Qore.enterMarkets(
    //     [...Markets]
    // )

    // await Qore.supply(
    //     '0x3A783ACe7fd7403584B89FB7979c536b22c2495C', 0,
    //     {
    //         value: ethers.parseEther("1")
    //     }
    // )

    let QTokenArtifact = await artifacts.readArtifact("QToken");
    var IQBNB = new ethers.Contract(
        "0x3A783ACe7fd7403584B89FB7979c536b22c2495C",
        QTokenArtifact.abi,
        owner
    );
    console.log(await IQBNB.balanceOf(owner));

    var IQQBT = new ethers.Contract(
        "0xED6f544b495159739676354DcB525a887359681a",
        QTokenArtifact.abi,
        owner
    );
    Qore.borrow("0xED6f544b495159739676354DcB525a887359681a", 100)
    var QBT = new ethers.Contract(
        "0x17B7163cf1Dbd286E262ddc68b553D899B93f526",
        QTokenArtifact.abi,
        owner
    );
    console.log(await QBT.balanceOf(owner));

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