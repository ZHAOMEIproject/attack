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
    {//info
        var ctokenaddress = "0xE554E874c9c60E45F1Debd479389C76230ae25A8"
        var WETHaddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
        // var CWETHaddress = "0xAffd437801434643B734D0B2853654876F66f7D7";
    }
    {
        var CTokenArtifact = await artifacts.readArtifact("CErc20");
        var CTOKEN20 = new ethers.Contract(
            ctokenaddress,
            CTokenArtifact.abi,
            owner
        );
        var compaddress = await CTOKEN20.comptroller()
        var compArtifact = await artifacts.readArtifact("Comptroller");
        var comp = new ethers.Contract(
            compaddress,
            compArtifact.abi,
            owner
        );
        // {//weth
        //     var WETH9Artifact = await artifacts.readArtifact("WETH9");
        //     var WETH = new ethers.Contract(
        //         WETHaddress,
        //         WETH9Artifact.abi,
        //         owner
        //     );
        //     await WETH.deposit({ value: ethers.parseEther("1") })
        //     console.log("WETH.balanceOf", await WETH.balanceOf(owner));
        //     var CWETH = new ethers.Contract(
        //         CWETHaddress,
        //         CTokenArtifact.abi,
        //         owner
        //     );
        // }
    }
    {
        let getAllMarkets = await comp.getAllMarkets()
        console.log(
            // "getAllMarkets:", getAllMarkets,
            "\n oracle : ", await comp.oracle(),
            "\n comp : ", compaddress,
        );
        let tasks = Array();
        for (let i in getAllMarkets) {
            const element = getAllMarkets[i];
            tasks.push(logtokeninfo(element, comp))
            // break
        }
        let tokeninfos = await Promise.all(tasks);
        console.log(tokeninfos);
        return
    }
    {//doing
        await comp.enterMarkets(
            [CWETHaddress]
        )
        await WETH.approve(CWETHaddress, ethers.parseEther("1000"))
        await CWETH.mint(ethers.parseEther("0.1"))
        console.log("CWETH.balanceOf", await CWETH.balanceOf(owner));
        await CTOKEN20.borrow(100)
    }
    return
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
        await CTOKEN20.name() + " : " + ctokenaddress + " token : " + await CTOKEN20.underlying() +
        " \n SUPPLY: " + await CTOKEN20.totalSupply() +
        " \n collateralFactor: " + market.collateralFactorMantissa +
        " \n price: " + await PriceOracle.getUnderlyingPrice(ctokenaddress) +
        // "\n uniprice: " +
        ""
    );
}