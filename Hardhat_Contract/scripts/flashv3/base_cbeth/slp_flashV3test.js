// npx hardhat run scripts/flashv3/base_cbeth/slp_flashV3test.js --network dev
// npx hardhat run scripts/flashv3/base_cbeth/slp_flashV3test.js --network hardhat
// npx hardhat run scripts/flashv3/base_cbeth/slp_flashV3test.js --network zhaomei
// npx hardhat run scripts/flashv3/base_cbeth/slp_flashV3test.js --network mzhaomei
const hre = require("hardhat");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();
    {//check vm
        console.log(
            await ethers.provider.getBalance(owner.address)
        );
    }
    let cbethprice = 0.853868;
    let info = {
        eth2cbeth_price: ethers.parseEther(cbethprice.toString()),
        ethvalue: ethers.parseEther("0.001"),

        cbeth2eth_price: ethers.parseEther((1 / cbethprice).toString()),
        withdrawethbalance: ethers.parseEther("0.001"),

        slp_cWETHv3: "0x8F44Fd754285aa6A2b8B9B97739B79746e0475a7",
        WETH: "0x4200000000000000000000000000000000000006",
        CBETH: "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
        fee: 100,
        multiplier: 2 * 1000,
        swap: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
        sil: 1000 - 100,
        scbeth: "0xfA48A40DAD139e9B1aF8dc82F37Da58cC3cA2867"
    }
    info["stakein"] = [
        info.WETH,//WETH
        info.CBETH,//CBETH
        info.fee,//fee
        info.multiplier,//杠杆
        info.swap,//swap address
        info.slp_cWETHv3,

        info.eth2cbeth_price,//wish price
        info.sil,
        info.scbeth
    ]
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
        info.scbeth
    ]
    var slp_cWETHv3 = new ethers.Contract(
        info.slp_cWETHv3,
        (await artifacts.readArtifact("IPool")).abi,
        owner
    );
    // var deployerNonce = await ethers.provider.getTransactionCount(owner.address);
    // var predictedAddress = await predictContractAddress(owner.address, (deployerNonce + 1));
    await wait(1000);
    let debttokeninfo = await slp_cWETHv3.getReserveData(info.WETH);
    console.log(debttokeninfo.variableDebtTokenAddress);
    return
    let debttoken_address = debttokeninfo.variableDebtTokenAddress;
    let debttoken = new ethers.Contract(
        debttoken_address,
        (await artifacts.readArtifact("ICreditDelegationToken")).abi,
        owner
    );
    var slp_flashV3test = await ethers.deployContract("slp_flashV3test");
    await debttoken.approveDelegation(
        slp_flashV3test,
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    )
    await slp_flashV3test.stakein(
        info.stakein
        , {
            value: info.ethvalue
        })
    await slp_flashV3test.stakeout(
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


async function wait(ms) {
    return new Promise(resolve => setTimeout(() => resolve(), ms));
}
