const { ecsign } = require('ethereumjs-util');
const ethers = require("ethers");
const { getPermitDigest } = require('./erc20')
exports.erc20_loc_getsign = async function erc20_loc_getsign(contractinfo, params, privateKey) {


    let provider = new ethers.JsonRpcProvider(contractinfo.network.url);
    let account = new ethers.Wallet(privateKey, provider);
    let contract = new ethers.Contract(
        contractinfo.address,
        contractinfo.abi,
        provider
    );
    let contractWithSigner = await contract.connect(account);
    let nonces = await contractWithSigner.nonces(account.address);
    const ownerPrivateKey = Buffer.from(privateKey.slice(2), 'hex')
    // 获取加密信息
    const digest = getPermitDigest(
        contractinfo.contractName, contractinfo.address, contractinfo.network.chainId,
        [
            params[0],
            params[1],
            params[2],
            nonces,
            params[3],
        ]
    )
    // get vrs
    let { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), ownerPrivateKey)
    let sign = "0x" + r.toString('hex') + s.toString('hex') + v;

    r = '0x' + sign.substring(2).substring(0, 64);
    s = '0x' + sign.substring(2).substring(64, 128);
    v = sign.substring(2).substring(128, 130);

    return [
        ...params,
        v,
        r,
        s
    ];
}
exports.WITHDRAW_loc_getsign = async function WITHDRAW_loc_getsign(contractinfo, params, privateKey) {

    const { getPermitDigest } = require('./VII_WITHDRAW_sign')
    // let provider = new ethers.JsonRpcProvider(contractinfo.network.url);
    // let account = new ethers.Wallet(privateKey, provider);
    // let contract = new ethers.Contract(
    //     contractinfo.address,
    //     contractinfo.abi,
    //     provider
    // );
    const ownerPrivateKey = Buffer.from(privateKey.slice(2), 'hex')
    // 获取加密信息
    const digest = getPermitDigest(
        "LADT_WITHDRAW", contractinfo.address, contractinfo.network.chainId,
        params
    )
    // get vrs
    let { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), ownerPrivateKey)
    let sign = "0x" + r.toString('hex') + s.toString('hex') + v;

    r = '0x' + sign.substring(2).substring(0, 64);
    s = '0x' + sign.substring(2).substring(64, 128);
    v = sign.substring(2).substring(128, 130);

    return {
        v,
        r,
        s
    }
}
