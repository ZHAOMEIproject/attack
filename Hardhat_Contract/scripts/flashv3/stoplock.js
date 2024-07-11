// npx hardhat run scripts/flashv3/stoplock.js --network dev
// npx hardhat run scripts/flashv3/stoplock.js --network hardhat
// npx hardhat run scripts/flashv3/stoplock.js --network zhaomei
// npx hardhat run scripts/flashv3/stoplock.js --network mzhaomei
// npx hardhat run scripts/flashv3/stoplock.js --network base
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('../tool/hh_log.js');
const { getcontractinfo } = require('../tool/id-readcontracts');
const { WITHDRAW_loc_getsign } = require("../tool/sign/loc_getsign");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();
    {//check vm
        console.log(
            owner.address,
            await ethers.provider.getBalance(owner.address)
        );
    }
    // await owner.sendTransaction({
    //     to: owner,
    //     gasPrice: 6000000n
    // })
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

async function logtokeninfo(ctokenaddress, comp) {
    var [owner, addr1, addr2] = await ethers.getSigners();
    let CTokenArtifact = await artifacts.readArtifact("CErc20");
    var CTOKEN20 = new ethers.Contract(
        ctokenaddress,
        CTokenArtifact.abi,
        owner
    );
    let market = await comp.markets(ctokenaddress);
    let PriceOracleArtifact = await artifacts.readArtifact("PriceOracle")
    var PriceOracle = new ethers.Contract(
        await comp.oracle(),
        PriceOracleArtifact.abi,
        owner
    );
    return (
        await CTOKEN20.name() + " : " + ctokenaddress +
        "\n SUPPLY: " + await CTOKEN20.totalSupply() +
        "\n collateralFactor: " + market.collateralFactorMantissa +
        "\n price: " + await PriceOracle.getUnderlyingPrice(ctokenaddress) +
        // "\n uniprice: " +
        ""
    );
}
async function predictContractAddress(deployerAddress, deployerNonce) {
    const rlp = require('rlp');
    const keccak = require('keccak');

    // RLP encode the sender address and nonce
    const encoded = rlp.encode([deployerAddress, deployerNonce]);

    // Hash the encoded data
    const hash = keccak('keccak256').update(encoded).digest('hex');

    // Take the last 20 bytes as the address
    const contractAddress = `0x${hash.slice(24)}`;
    return contractAddress;
}