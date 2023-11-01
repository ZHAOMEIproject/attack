// npx hardhat run scripts/all_test.js --network dev
// npx hardhat run scripts/all_test.js --network hardhat
// npx hardhat run scripts/all_test.js --network zhaomei
// npx hardhat run scripts/all_test.js --network mzhaomei
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('../tool/hh_log.js');
const { getcontractinfo } = require('../tool/id-readcontracts.js');
const { WITHDRAW_loc_getsign } = require("../tool/sign/loc_getsign.js");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();

    let compArtifact = await artifacts.readArtifact("Comptroller");
    var comp = new ethers.Contract(
        "0x67340Bd16ee5649A37015138B3393Eb5ad17c195",
        compArtifact.abi,
        owner
    );
    let CTokenArtifact = await artifacts.readArtifact("CErc20");
    var CFTS = new ethers.Contract(
        "0x854C266b06445794FA543b1d8f6137c35924C9EB",
        CTokenArtifact.abi,
        owner
    );
    var CLP = new ethers.Contract(
        "0xFF6296Fd1Cf18fDFCa02824801ebe1481b974391",
        CTokenArtifact.abi,
        owner
    );
    let CEtherArtifact = await artifacts.readArtifact("CEther");
    var CBNB = new ethers.Contract(
        "0xE24146585E882B6b59ca9bFaaaFfED201E4E5491",
        CEtherArtifact.abi,
        owner
    );

    console.log(await comp.borrowCaps(CFTS.target));
    console.log(await comp.borrowCaps(CLP.target));
    console.log(await CFTS.totalBorrows());
    console.log(await CLP.totalBorrows());
    return

    await comp.enterMarkets(
        [
            CBNB.target
        ]
    );
    await CBNB.mint({ value: ethers.parseEther("10") });
    await CFTS.borrow(ethers.parseEther("0.5"));
    await CLP.borrow(ethers.parseEther("0.5"));

    var FTS = new ethers.Contract(
        "0x4437743ac02957068995c48E08465E0EE1769fBE",
        CTokenArtifact.abi,
        owner
    );
    var LP = new ethers.Contract(
        "0xc69f2139a6Ce6912703AC10e5e74ee26Af1b4a7e",
        CTokenArtifact.abi,
        owner
    );

    console.log(
        "\nFTS:", await FTS.blanceOf(owner),
        "\nLP:", await LP.blanceOf(owner),
    );




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