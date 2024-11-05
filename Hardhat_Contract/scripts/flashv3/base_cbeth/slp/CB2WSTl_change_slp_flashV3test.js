// npx hardhat run scripts/flashv3/base_cbeth/slp/WST2CBl_change_slp_flashV3test.js --network dev
// npx hardhat run scripts/flashv3/base_cbeth/slp/WST2CBl_change_slp_flashV3test.js --network hardhat
// npx hardhat run scripts/flashv3/base_cbeth/slp/WST2CBl_change_slp_flashV3test.js --network zhaomei
// npx hardhat run scripts/flashv3/base_cbeth/slp/WST2CBl_change_slp_flashV3test.js --network mzhaomei
// npx hardhat run scripts/flashv3/base_cbeth/slp/WST2CBl_change_slp_flashV3test.js --network base
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
    let A2Bprice = 1.1
    let multiplier = 10;
    let swapfee = 1 / 10 ** 4
    let A_swapamount = 1;
    let totalfee = (swapfee * 2 * 3.5 * multiplier)
    console.log(
        "totalfee:", totalfee * 100,
        "one mult fee:", totalfee * 100 / multiplier
    );
    let info = {
        Ain: ethers.parseEther(A_swapamount.toString()),
        limitA2Bprice: ethers.parseEther(A2Bprice.toString()),
        slp_cWETHv3: "0x8F44Fd754285aa6A2b8B9B97739B79746e0475a7",
        WETH: "0x4200000000000000000000000000000000000006",
        CBETH: "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
        otherCBETH: "0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22",
        // CBETH: "0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22",
        // otherCBETH: "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
        fee: swapfee * 10 ** 6,//
        multiplier: multiplier * (10 ** 4),
        // uinswap
        swap: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
        // pancakeswap
        // swap: "0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997",
        // Aerodrome
        // swap: "0x254cF9E1E6e233aa1AC962CB9B05b2cfeAaE15b0",

        sil: (10 ** 4) - 0,
        flashV3test: "0x545cd3b239bacf1c1a8009826e338bedd312aab6",
    }
    info["change"] = [
        // [info.CBETH,info.otherCBETH],
        // [info.fee],
        [info.CBETH, info.WETH, info.otherCBETH],
        [info.fee, info.fee],
        info.swap,
        info.slp_cWETHv3,
        info.limitA2Bprice,
        info.Ain,
        info.sil
    ]
    var slp_flashV3test = new ethers.Contract(
        info.flashV3test,
        (await artifacts.readArtifact("slp_flashV3test")).abi,
        owner
    );
    console.log(info["change"]);
    let scbeth = new ethers.Contract(
        "0x2c159A183d9056E29649Ce7E56E59cA833D32624",
        (await artifacts.readArtifact("contracts/flash/seamlessprotocol/dependencies/openzeppelin/contracts/IERC20.sol:IERC20")).abi,
        owner
    );
    // if ((await scbeth.allowance(owner, slp_flashV3test)) < info.Ain) {
    // await scbeth.approve(slp_flashV3test, "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
    // }
    await slp_flashV3test.twice_changing_collateral(info["change"]);
    console.log("finish changing");
    // console.log(
    //     await slp_flashV3test.get_userinfo(info["change"]),
    // );

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
