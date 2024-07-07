// npx hardhat run scripts/load_flashV3test.js --network dev
// npx hardhat run scripts/load_flashV3test.js --network hardhat
// npx hardhat run scripts/load_flashV3test.js --network zhaomei
// npx hardhat run scripts/load_flashV3test.js --network mzhaomei
const hre = require("hardhat");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();
    {//check vm
        console.log(
            await ethers.provider.getBalance(owner.address)
        );
    }
    let info = {
        eth2cbeth_price: ethers.parseEther("0.930"),
        ethvalue: ethers.parseEther("0.001"),

        cbeth2eth_price: ethers.parseEther((1 / 0.930).toString()),
        withdrawethbalance: ethers.parseEther("5"),

        cWETHv3: "0x46e6b214b524310239732D51387075E0e70970bf",
        WETH: "0x4200000000000000000000000000000000000006",
        CBETH: "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22",
        fee: 100,
        multiplier: 10 * 1000,
        swap: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
        sil: 1000 - 2,
        flashV3test: "0xEAb3F87AaE570e8E4fb4b79a954047A8aA8B5ff8",
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
    var flashV3test = new ethers.Contract(
        info.flashV3test,
        (await artifacts.readArtifact("flashV3test")).abi,
        owner
    );
    let WETH = new ethers.Contract(
        info.WETH,
        (await artifacts.readArtifact("IWETH")).abi,
        owner
    );
    console.log(info.stakeout);
    await flashV3test.stakeout(
        info.stakeout)
    await WETH.withdraw(
        await WETH.balanceOf(owner)
    )
    console.log(
        "weth:", ethers.formatEther(
            await WETH.balanceOf(owner)
        ),
        "eth:", await ethers.provider.getBalance(owner.address)
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