// npx hardhat run scripts/1test.js --network dev
// npx hardhat run scripts/1test.js --network hardhat
// npx hardhat run scripts/1test.js --network zhaomei
// npx hardhat run scripts/1test.js --network mzhaomei
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('./tool/hh_log.js');
const { getcontractinfo } = require('./tool/id-readcontracts');
const { WITHDRAW_loc_getsign } = require("./tool/sign/loc_getsign");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();
    {//check vm
        console.log(
            await ethers.provider.getBalance(owner.address)
        );
    }
    let info = {
        eth2cbeth_price: ethers.parseEther("0.93153"),
        ethvalue: ethers.parseEther("0.1"),

        cbeth2eth_price: ethers.parseEther((1 / 0.93153).toString()),
        withdrawethbalance: ethers.parseEther("0.01"),

        cWETHv3: "0x46e6b214b524310239732D51387075E0e70970bf",
        WETH: "0x4200000000000000000000000000000000000006",
        CBETH: "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22",
        fee: 100,
        multiplier: 10 * 1000,
        swap: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
        sil: 1000 - 2
    }
    info["stakein"] = [
        info.WETH,//WETH
        info.CBETH,//CBETH
        info.fee,//fee
        info.multiplier,//杠杆
        info.swap,//swap address
        info.cWETHv3,

        info.eth2cbeth_price,//wish price
        info.sil,
    ]
    info["stakeout"] = [
        info.WETH,//WETH
        info.CBETH,//CBETH
        info.fee,//fee
        info.multiplier,//杠杆
        info.swap,//swap address
        info.cWETHv3,

        info.cbeth2eth_price,//wish price
        info.withdrawethbalance,//wish price
        info.sil,
    ]

    var cWETHv3 = new ethers.Contract(
        info.cWETHv3,
        (await artifacts.readArtifact("CometMainInterface")).abi,
        owner
    );
    var deployerNonce = await ethers.provider.getTransactionCount(owner.address);
    var predictedAddress = await predictContractAddress(owner.address, (deployerNonce + 1));
    await cWETHv3.allow(predictedAddress, true);
    var flashV3test = await ethers.deployContract("flashV3test");
    await flashV3test.stakein(
        info.stakein
        , {
            value: info.ethvalue
        })
    await flashV3test.stakeout(
        info.stakeout)
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