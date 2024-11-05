// npx hardhat run scripts/flashv3/base_cbeth/slp/wst_stakeout.js --network dev
// npx hardhat run scripts/flashv3/base_cbeth/slp/wst_stakeout.js --network hardhat
// npx hardhat run scripts/flashv3/base_cbeth/slp/wst_stakeout.js --network zhaomei
// npx hardhat run scripts/flashv3/base_cbeth/slp/wst_stakeout.js --network mzhaomei
// npx hardhat run scripts/flashv3/base_cbeth/slp/wst_stakeout.js --network base
const hre = require("hardhat");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();
    {//check vm
        console.log(
            owner.address,
            await ethers.provider.getBalance(owner.address)
        );
    }
    let cbethprice = 0.851744;
    let multiplier = 2200;
    let info = {
        slp_cWETHv3: "0x8F44Fd754285aa6A2b8B9B97739B79746e0475a7",
        WETH: "0x4200000000000000000000000000000000000006",
        CBETH: "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
        fee: 100,//
        multiplier: multiplier * (10 ** 4),
        // uinswap
        swap: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
        // pancakeswap
        // swap: "0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997",
        // Aerodrome
        // swap: "0x254cF9E1E6e233aa1AC962CB9B05b2cfeAaE15b0",

        sil: (10 ** 4) - 3,
        flashV3test: "0x545cd3b239bacf1c1a8009826e338bedd312aab6",

        cbeth2eth_price: ethers.parseEther((1 / cbethprice).toString()),
        withdrawethbalance: ethers.parseEther("0.001"),
    }
    info["stakeout"] = [
        info.WETH,//WETH
        info.CBETH,//CBETH
        info.fee,//fee
        info.multiplier,//杠杆
        info.swap,//swap address
        info.slp_cWETHv3,
        info.cbeth2eth_price,//wish price
        info.withdrawethbalance,//wish price
        info.sil,
    ]
    console.log(info["stakeout"]);
    var slp_flashV3test = new ethers.Contract(
        info.flashV3test,
        (await artifacts.readArtifact("slp_flashV3test")).abi,
        owner
    );
    let deb_weth = new ethers.Contract(
        "0x4cebc6688faa595537444068996ad9a207a19f13",
        (await artifacts.readArtifact("contracts/flash/seamlessprotocol/dependencies/openzeppelin/contracts/IERC20.sol:IERC20")).abi,
        owner
    );
    let atoken_cbeth = new ethers.Contract(
        "0xfA48A40DAD139e9B1aF8dc82F37Da58cC3cA2867",
        (await artifacts.readArtifact("contracts/flash/seamlessprotocol/dependencies/openzeppelin/contracts/IERC20.sol:IERC20")).abi,
        owner
    );

    await slp_flashV3test.stakeout(
        info.stakeout)
    console.log("finish stakeout");
    console.log(
        owner.address, ": ",
        await ethers.provider.getBalance(owner.address)
    );


    console.log(
        "atoken_cbeth: ",
        await atoken_cbeth.balanceOf(owner),
        "WETHdeb_cbeth: ",
        await deb_weth.balanceOf(owner),
    );


}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

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


async function wait(ms) {
    return new Promise(resolve => setTimeout(() => resolve(), ms));
}
