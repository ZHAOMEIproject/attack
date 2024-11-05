// npx hardhat run scripts/old/test.js --network dev
// npx hardhat run scripts/old/test.js --network hardhat
// npx hardhat run scripts/old/test.js --network zhaomei
// npx hardhat run scripts/old/test.js --network mzhaomei
// npx hardhat run scripts/old/test.js --network base
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('../tool/hh_log.js');
const { getcontractinfo } = require('../tool/id-readcontracts');
const { WITHDRAW_loc_getsign } = require("../tool/sign/loc_getsign");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();

    {
        const FNXA = await ethers.deployContract("FNXA", ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"]);
        await FNXA.waitForDeployment();
        await writer_info_all(
            network,
            await artifacts.readArtifact("FNXA"),
            FNXA,
            ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"]
        );

        console.log(
            "npx hardhat verify ", FNXA.target, `--constructor-args ./Arguments/${network.name}/FNXA.json`, "--network ", network.name
        );


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