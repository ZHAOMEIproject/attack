// npx hardhat run scripts/flash.js --network dev
// npx hardhat run scripts/flash.js --network hardhat
// npx hardhat run scripts/flash.js --network zhaomei
// npx hardhat run scripts/flash.js --network mzhaomei
const hre = require("hardhat");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();
    {
        {
            const flash = await ethers.deployContract("flash", { value: ethers.parseEther("1") });
            await flash.waitForDeployment();
            // await flash.uniswapV2Flash("0x01");

            await flash.liquidity(
                "0xe16eA27A69C63BCf73959497D142B19813da0Ec8",
                { value: ethers.parseEther("0.67") }
            );
            // let estimatedGas = await flash.liquidity.estimateGas(
            //     "0x871a12B7eA019109565Bb4B2CdCe2A90c9952Bb5",
            //     { value: ethers.parseEther("0.048") }
            // );
            // console.log(estimatedGas);

        }
    }
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
