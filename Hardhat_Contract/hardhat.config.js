require("@nomicfoundation/hardhat-toolbox");
// require("@nomicfoundation/hardhat-verify");
// npm install --save-dev @openzeppelin/hardhat-upgrades
// npm install --save-dev @nomicfoundation/hardhat-ethers ethers # peer dependencies
require('@openzeppelin/hardhat-upgrades');


/** @type import('hardhat/config').HardhatUserConfig */
const secretinfo = require(`../../zm_privateinfo/.secret.js`);
module.exports = secretinfo.hardhatset;