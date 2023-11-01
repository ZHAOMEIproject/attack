const fs = require('fs');
const path = require('path');
const util = require('util');

const writeFile = util.promisify(fs.writeFile);
/**
 * 记录合约发布地址
 * @param {*} deployments json
 * @param {*} name 类型
 * @param {*} network 网络
 */
// for Hardhat deployment
var dir;

var info = {};
var deploymentPath;
async function writer_info_all(network, Artifact, contract, Argument) {
  await baseinit(network, Artifact, contract);

  info["constructorArguments"] = Argument;
  await writer_Arguments(network, Artifact)
  await baseinit2(network, Artifact);
}
async function writer_info_all_proxy(network, Artifact, contract, Argument, proxyaddr) {
  await baseinit(network, Artifact, contract);

  info["constructorArguments"] = Argument;
  await writer_Arguments(network, Artifact)
  info["p_address"] = proxyaddr;

  await baseinit2(network, Artifact);
}
async function writer_info(network, Artifact, contract) {
  await baseinit(network, Artifact, contract);

  await baseinit2(network, Artifact);
}

async function baseinit(network, Artifact, contract) {
  if (contract.target) {
    contract.address = contract.target
  }
  deploymentPath = path.resolve(__dirname, `../../deployments`)
  await creatfile(deploymentPath);
  await set_base_info(network, Artifact, contract);
}
async function baseinit2(network, Artifact) {
  dir = deploymentPath + `/${network.name}/${Artifact.contractName}.json`;
  await writeFile(dir, JSON.stringify(info, replacer, 2));
  dir = deploymentPath + `/newinfo/${Artifact.contractName}.json`;
  await writeFile(dir, JSON.stringify(info, replacer, 2));
  console.log(`Exported deployments into ${deploymentPath}`);
  await updatedeployments();
}
async function creatfile(deploymentPath) {
  if (!fs.existsSync(deploymentPath)) {
    await fs.mkdirSync(deploymentPath, { recursive: true });
  }
  dir = deploymentPath + `/newinfo`;
  if (!fs.existsSync(dir)) {
    await fs.mkdirSync(dir, { recursive: true });
  }
  dir = deploymentPath + `/${network.name}`;
  if (!fs.existsSync(dir)) {
    await fs.mkdirSync(dir, { recursive: true });
  }
}
async function set_base_info(network, Artifact, contract) {
  info["contractName"] = Artifact.contractName;
  info["abi"] = Artifact.abi;
  info["address"] = contract.address;
  info["target"] = contract.target;
  // info["blocknumber"] = contract.provider._maxInternalBlockNumber;
  info["blocknumber"] = await contract.runner.provider.getBlockNumber();
  info["constructorArguments"] = [];
  info["network"] = {};
  info.network["name"] = network.name;
  info.network["chainId"] = network.config.chainId;
  info.network["url"] = network.config.url;
  if (!info.network["url"]) {
    info.network["url"] = "http://127.0.0.1:8545"
  }
}
async function writer_Arguments(network, Artifact) {
  await creatfile(path.resolve(__dirname, `../../Arguments`));
  dir = (
    path.resolve(__dirname, `../../Arguments`) +
    `/${network.name}/${Artifact.contractName}.json`
  )
  await writeFile(
    dir,
    JSON.stringify(
      info.constructorArguments,
      replacer,
      2
    )
  );
}

const { getcontractinfo } = require("./id-readcontracts.js")
async function updatedeployments() {
  var contractinfo = await getcontractinfo();
  dir = deploymentPath + `/all.json`;
  await writeFile(dir, JSON.stringify(contractinfo));
}

module.exports = {
  writer_info,
  writer_info_all,
  writer_info_all_proxy
}
function replacer(key, value) {
  if (typeof value === 'bigint') {
    return value.toString(); // 将 BigInt 转换为字符串
  } else {
    return value; // 其他类型的值保持不变
  }
}