// npx hardhat node
// npx hardhat run scripts/erc7702test.js
// npx hardhat run scripts/erc7702test.js --network dev
// npx hardhat run scripts/erc7702test.js --network bnbtest
// npx hardhat run scripts/erc7702test.js --network zhaomei
// npx hardhat verify --network bnbtest --libraries libraries.json 0xba1cbb3d8a16dd9368a5fde5108cff1c0220e15b "0x6cc4707D4CB502E3aaEeDADB2F7f552c1F9C523c" "0x3792181b87874938d05c3cd4f8c9d3e475fac298"

const { ethers } = require("hardhat");

async function main() {
    {
        // const [owner, addr1, addr2] = await ethers.getSigners();
        // const token = await ethers.deployContract("TUSDT");
        // console.log("bf", {
        //     account: owner.address,
        //     balanceOf: await token.balanceOf(owner.address),
        // });
        // // ERC‑20 合约地址和 ABI（这里只需部分 ABI）
        // // const tokenAddress = "0x55d398326f99059ff775485246999027b3197955";
        // // const tokenAbi = [
        // //     "function balanceOf(address) view returns (uint256)",
        // //     "function decimals() view returns (uint8)",
        // //     "function transfer(address to, uint amount) returns (bool)"
        // // ];
        // // const token = new ethers.Contract(tokenAddress, tokenAbi);

        // // 查询余额
        // const myAddress = owner.address;
        // const decimals = await token.decimals();
        // // 转账参数
        // const to = '0x78c61d4b793459adc27805371ba136c38f2208b8';              // 收款人
        // const amount = '0.1';                   // 转账数量（单位：代币）
        // const amountParsed = ethers.utils.parseUnits(amount, decimals);

        // // 发起转账
        // const tx = await token.transfer(to, amountParsed);
        // const receipt = await tx.wait();
        // console.log("af", {
        //     account: to,
        //     balanceOf: await token.balanceOf(to),
        // });
    }
    {
        const [firstSigner, sponsorSigner, addr2] = await ethers.getSigners();
        const token = await ethers.deployContract("TUSDT");
        console.log("bf", {
            account: firstSigner.address,
            balanceOf: await token.balanceOf(firstSigner.address),
        });
        async function createAuthorization(nonce) {
            const auth = await firstSigner.authorize({
                address: targetAddress,
                nonce: nonce,
            });

            console.log("Authorization created with nonce:", auth.nonce);
            return auth;
        }
        async function sendNonSponsoredTransaction() {
            console.log("\n=== TRANSACTION 1: NON-SPONSORED (ETH TRANSFERS) ===");
            const currentNonce = await firstSigner.getNonce();
            console.log("Current nonce for first signer:", currentNonce);
            // Create authorization with incremented nonce for same-wallet transactions
            const auth = await createAuthorization(currentNonce + 1);

            // Prepare calls for ETH transfers
            const calls = [
                // to address, value, data
                [ethers.ZeroAddress, ethers.parseEther("0.001"), "0x"],
                [recipientAddress, ethers.parseEther("0.002"), "0x"],
            ];

            // Create contract instance and execute
            const delegatedContract = new ethers.Contract(
                firstSigner.address,
                contractABI,
                firstSigner
            );

            const tx = await delegatedContract["execute((address,uint256,bytes)[])"](
                calls,
                {
                    type: 4,
                    authorizationList: [auth],
                }
            );

            console.log("Non-sponsored transaction sent:", tx.hash);

            const receipt = await tx.wait();
            console.log("Receipt for non-sponsored transaction:", receipt);

            return receipt;
        }
        await sendNonSponsoredTransaction()
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
