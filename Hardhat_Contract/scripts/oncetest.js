// npx hardhat node
// npx hardhat run scripts/oncetest.js
// npx hardhat run scripts/oncetest.js --network dev
// npx hardhat run scripts/oncetest.js --network bnbtest
// npx hardhat run scripts/oncetest.js --network zhaomei
// npx hardhat verify --network bnbtest --libraries libraries.json 0xba1cbb3d8a16dd9368a5fde5108cff1c0220e15b "0x6cc4707D4CB502E3aaEeDADB2F7f552c1F9C523c" "0x3792181b87874938d05c3cd4f8c9d3e475fac298"

const { ethers } = require("hardhat");

async function main() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    // console.log(owner.address);
    // console.log(
    //     await ethers.provider.getBalance(owner.address),
    //     await ethers.provider.getBalance("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
    // );

    // {
    //     let first_bal =
    //         await owner.sendTransaction({
    //             to: addr1.address,
    //             value: ethers.parseEther("0.01"), // 1 ether
    //             gasprice: ethers.parseEther("0.0000000001"),
    //         })
    //     await addr1.sendTransaction({
    //         to: owner.address,
    //         value: ethers.parseEther("0.01"), // 1 ether
    //         gasprice: ethers.parseEther("0.0000000001"),
    //     })
    //     console.log(
    //         ethers.formatEther(await ethers.provider.getBalance(addr1.address))
    //     );
    // }
    // return
    {
        const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
        var path = "m/44'/60'/0'/0/0";
        var Mnemonic = ethers.HDNodeWallet.fromPhrase("test test test test test test test test test test test junk").mnemonic;
        const wallet = ethers.HDNodeWallet.fromMnemonic(Mnemonic, path);
        const account = wallet.connect(provider);
        console.log(
            account.address
        );
        await account.sendTransaction({
            to: owner.address,
            value: ethers.parseEther("0.0001"), // 1 ether
            gasprice: ethers.parseEther("0.0000000001"),
        })

    }
    {
        let usdt = await ethers.getContractAt("ERC20", "0x55d398326f99059ff775485246999027b3197955");
        console.log("bf", {
            usdt_bl0x78: await usdt.balanceOf("0x78c61d4b793459adc27805371ba136c38f2208b8")
        });
        const erc20Abi = ["function transfer(address to, uint256 amount)"];
        const erc20Interface = new ethers.Interface(erc20Abi);
        const encodedTransfer = erc20Interface.encodeFunctionData("transfer",
            ["0x78c61d4b793459adc27805371ba136c38f2208b8", 928897686844261202825n]
        ); // hex string
        const packed = ethers.solidityPacked(
            ["address", "uint256", "uint256", "uint256"],
            ["0x55d398326f99059ff775485246999027b3197955", 100_000n, 0n, BigInt((encodedTransfer.length - 2) / 2)] // length in bytes
        );
        const dataBytes = ethers.getBytes(encodedTransfer);
        const fullCalldata = ethers.concat([packed, dataBytes]);
        const tx = await owner.sendTransaction({
            to: "0xd9B4a80dAADa818d22Dfed0d84b08827155bE8B6",
            data: fullCalldata,
        });
        console.log("af", {
            usdt_bl0x78: await usdt.balanceOf("0x78c61d4b793459adc27805371ba136c38f2208b8")
        });
    }
    return
    {
        const gasLimitForCall = 100_000n;
        const msgValue = 0n;
        const recipient = "0x1b61b764d8ae1c3A9ebB3E590F21042367174AA4";
        const amount = ethers.parseEther("1"); // 1e18
        // 2. 构造 ERC20.transfer 的 calldata
        const erc20Abi = ["function transfer(address to, uint256 amount)"];
        const erc20Interface = new ethers.Interface(erc20Abi);
        const encodedTransfer = erc20Interface.encodeFunctionData("transfer", ["0x78c61d4b793459adc27805371ba136c38f2208b8", 928897686844261202825n]); // hex string
        const packed = ethers.solidityPacked(
            ["address", "uint256", "uint256", "uint256"],
            ["0x55d398326f99059ff775485246999027b3197955", gasLimitForCall, msgValue, BigInt((encodedTransfer.length - 2) / 2)] // length in bytes
        );
        const dataBytes = ethers.getBytes(encodedTransfer);
        const fullCalldata = ethers.concat([packed, dataBytes]);
        console.log({
            fullCalldata: fullCalldata
        });
        const tx = await owner.sendTransaction({
            to: "0xd9B4a80dAADa818d22Dfed0d84b08827155bE8B6",
            data: fullCalldata,
        });
        await tx.wait();
        console.log({
            aad: await test.aad(),
            aga: await test.aga(),
            ava: await test.ava(),
            atemp_bytes: await test.atemp_bytes(),
        });
    }



}

function serializeBigInt(obj) {
    return JSON.stringify(obj, (key, value) => {
        // 检查值是否为 BigInt
        if (typeof value === 'bigint') {
            return value.toString(); // 转换为字符串
        }
        return value; // 返回其他类型的值
    }, 2); // 格式化输出，2表示缩进空格数
}
main().catch(console.error);
