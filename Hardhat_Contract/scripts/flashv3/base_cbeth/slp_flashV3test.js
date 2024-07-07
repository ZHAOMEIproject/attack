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
    let cbethprice = 0.853794;
    let multiplier = 10;
    let eth_amount = 1;
    let swapfee = 1 / 10 ** 4
    let totalfee = (swapfee * 2 * 3.5 * multiplier)
    console.log(
        "totalfee:", totalfee * 100,
        "one mult fee:", totalfee * 100 / multiplier
    );
    let info = {
        eth2cbeth_price: ethers.parseEther(cbethprice.toString()),
        ethvalue: ethers.parseEther(eth_amount.toString()),

        cbeth2eth_price: ethers.parseEther((eth_amount / cbethprice).toString()),
        withdrawethbalance: ethers.parseEther((eth_amount * (1 - totalfee)).toString()),

        slp_cWETHv3: "0x8F44Fd754285aa6A2b8B9B97739B79746e0475a7",
        WETH: "0x4200000000000000000000000000000000000006",
        CBETH: "0xc1cba3fcea344f92d9239c08c0568f6f2f0ee452",
        fee: swapfee * 10 ** 6,//
        multiplier: multiplier * (10 ** 4),
        swap: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
        sil: (10 ** 4) - 100
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
    ]
    var slp_cWETHv3 = new ethers.Contract(
        info.slp_cWETHv3,
        (await artifacts.readArtifact(
            "contracts/flash/seamlessprotocol/interfaces/IPool.sol:IPool"
        )).abi,
        owner
    );
    await slp_cWETHv3.setUserEMode(1);
    // var deployerNonce = await ethers.provider.getTransactionCount(owner.address);
    // var predictedAddress = await predictContractAddress(owner.address, (deployerNonce + 1));
    var slp_flashV3test = await ethers.deployContract("slp_flashV3test");
    let debttoken_address = (await slp_flashV3test.getdebttokenadd(slp_cWETHv3, info.WETH)).variableDebtTokenAddress;

    let debttoken = new ethers.Contract(
        debttoken_address,
        (await artifacts.readArtifact("VariableDebtToken")).abi,
        owner
    );
    await debttoken.approveDelegation(
        slp_flashV3test,
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    )

    await slp_flashV3test.stakein(
        info.stakein, {
        value: info.ethvalue
    })
    let scbeth = new ethers.Contract(
        (await slp_flashV3test.getdebttokenadd(slp_cWETHv3, info.CBETH)).aTokenAddress,
        (await artifacts.readArtifact("contracts/flash/seamlessprotocol/dependencies/openzeppelin/contracts/IERC20.sol:IERC20")).abi,
        owner
    );
    console.log(
        "scbeth.balanceOf:", await scbeth.balanceOf(owner),
        "debttoken.balanceOf:", await debttoken.balanceOf(owner)
    );
    await scbeth.approve(slp_flashV3test, "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
    let bf_amount = await ethers.provider.getBalance(owner.address);
    await slp_flashV3test.stakeout(
        info.stakeout)
    let af_amount = await ethers.provider.getBalance(owner.address);
    console.log(
        ethers.formatEther(
            af_amount - bf_amount
        ),
        Number(af_amount - bf_amount) / 10 ** 16
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
