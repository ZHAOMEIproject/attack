// npx hardhat run scripts/flashv3/base_cbeth/flashV3test.js --network dev
// npx hardhat run scripts/flashv3/base_cbeth/flashV3test.js --network hardhat
// npx hardhat run scripts/flashv3/base_cbeth/flashV3test.js --network zhaomei
// npx hardhat run scripts/flashv3/base_cbeth/flashV3test.js --network mzhaomei
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
        eth2cbeth_price: ethers.parseEther("0.9"),
        ethvalue: ethers.parseEther("0.001"),

        cbeth2eth_price: ethers.parseEther((1 / 0.9).toString()),
        withdrawethbalance: ethers.parseEther("0.001"),

        cWETHv3: "0x46e6b214b524310239732D51387075E0e70970bf",
        WETH: "0x4200000000000000000000000000000000000006",
        CBETH: "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22",
        fee: 100,
        multiplier: 9 * 1000,
        swap: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
        sil: 1000 - 100
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

    console.log(
        ethers.utils.formatEther(
            await ethers.provider.getBalance(owner.address)
        )
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