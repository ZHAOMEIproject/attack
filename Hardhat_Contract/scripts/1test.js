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
    {
        {
            var Vaultaddress = "0x489ee077994B6658eAfA855C308275EAd8097C4A"
            var WETHaddress = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
        }
        {
            var VaultArtifact = await artifacts.readArtifact("Vault");
            var Vault = new ethers.Contract(
                Vaultaddress,
                VaultArtifact.abi,
                owner
            );
            var WETHArtifact = await artifacts.readArtifact("WETH9");
            var WETH = new ethers.Contract(
                WETHaddress,
                WETHArtifact.abi,
                owner
            );
        }
        {
            console.log(await Vault.);
            await WETH.deposit({ value: ethers.parseEther("1") })
            await WETH.transfer(Vaultaddress, ethers.parseEther("1"))

        }
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