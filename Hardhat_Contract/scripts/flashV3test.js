// npx hardhat run scripts/flash.js --network dev
// npx hardhat run scripts/flash.js --network hardhat
// npx hardhat run scripts/flash.js --network zhaomei
// npx hardhat run scripts/flash.js --network mzhaomei
const hre = require("hardhat");
var contractinfo = new Object();
async function main() {
    var [owner, addr1, addr2] = await ethers.getSigners();
    var USDA_add
    var mek_add
    var LP_add
    var UniswapV3 = "0xFE6508f0015C778Bdcc1fB5465bA5ebE224C9912"
    var fee = "100"
    var eth1 = ethers.parseEther("1");
    var MEKprice = eth1;
    var f_mekprice = 5n;
    var f_mekprice_d = 100n;

    var p_in_USDA = ethers.parseEther("1");
    var p_in_mek = ethers.parseEther("1");
    var slip = 10n;
    var slip_d = 100n;
    var deadline = 9999999999
    var start_time = 1;
    var facktime = 1;

    {//USDA CREAT
        const d_USDA = await ethers.getContractFactory("USDA");
        var USDA = await upgrades.deployProxy(d_USDA);
        await USDA.waitForDeployment();
        USDA_add = await USDA.target

        const c_Address = await upgrades.erc1967.getImplementationAddress(await USDA.target);
        let Artifact = await artifacts.readArtifact("USDA");
        await writer_info_all_proxy(network, Artifact, USDA, "", c_Address);
        console.log("USDA_base deployed to:", c_Address);
        console.log("USDA deployed to:", await USDA.target);

    }
    {//MEK CREAT
        const MEK = await ethers.getContractFactory("MEK");
        var MEK = await upgrades.deployProxy(MEK);
        await MEK.waitForDeployment();
        mek_add = await MEK.target

        const c_Address = await upgrades.erc1967.getImplementationAddress(await MEK.target);
        let Artifact = await artifacts.readArtifact("MEK");
        await writer_info_all_proxy(network, Artifact, MEK, "", c_Address);
        console.log("mek_base deployed to:", c_Address);
        console.log("MEK deployed to:", await MEK.target);
    }
    {//UNISWAP V3 POOL CREAT AND MINT
        await USDA.approve(UniswapV3, await USDA.totalSupply())
        await MEK.approve(UniswapV3, await MEK.totalSupply())

        console.log("approve end");
        var univ3oracle = await hre.ethers.deployContract("univ3oracle");
        await univ3oracle.waitForDeployment();

        let Artifact = await artifacts.readArtifact("univ3oracle");
        await writer_info(network, Artifact, univ3oracle);


        var [tick, sqrtRatioX96] = await univ3oracle.gettick(eth1, MEKprice, mek_add, USDA_add)
        var [tickA, dieqi1] = await univ3oracle.gettick(eth1, MEKprice * (f_mekprice_d + f_mekprice) / f_mekprice_d, mek_add, USDA_add)
        var [tickB, dieqi2] = await univ3oracle.gettick(eth1, MEKprice * (f_mekprice_d - f_mekprice) / f_mekprice_d, mek_add, USDA_add)

        var tickUpper, tickLower;
        tickA > tickB
            ? [tickUpper, tickLower] = [tickA, tickB]
            : [tickUpper, tickLower] = [tickB, tickA];
        var half = (tickUpper - tickLower) / 2n / 100n * 100n;
        tickLower = (tick / 100n) * 100n - half
        tickUpper = (tick / 100n) * 100n + half


        var Iuniv3 = await ethers.getContractAt("Iuniv3", UniswapV3)
        var calls = [];
        calls.push(Iuniv3.interface.encodeFunctionData("createAndInitializePoolIfNecessary", [
            USDA_add,
            mek_add,
            fee,
            sqrtRatioX96
        ]))
        var multicalldata;
        multicalldata = Iuniv3.interface.encodeFunctionData("multicall",
            [
                calls
            ]
        )
        await ethers.provider.estimateGas({
            from: owner.address,
            to: Iuniv3.target,
            data: multicalldata,
            value: 0
        })
        // while (true) {
        //     try {
        //         await ethers.provider.estimateGas({
        //             from: owner.address,
        //             to: Iuniv3.target,
        //             data: multicalldata,
        //             value: 0
        //         })
        //         break;
        //     } catch (error) {
        //         console.log("error,wait 500ms");
        //         await sleep(500)
        //     }
        // }
        console.log("pool creat end");
        console.log(tickLower, tickUpper);
        calls.push(Iuniv3.interface.encodeFunctionData("mint", [
            [
                USDA_add,
                mek_add,
                fee,
                tickLower,
                tickUpper,
                p_in_USDA,
                p_in_mek,
                p_in_USDA * (slip_d - slip) / slip_d,
                p_in_mek * (slip_d - slip) / slip_d,
                owner.address,
                deadline
            ]
        ]))
        multicalldata = Iuniv3.interface.encodeFunctionData("multicall",
            [
                calls
            ]
        )
        console.log(
            await ethers.provider.estimateGas({
                from: owner.address,
                to: Iuniv3.target,
                data: multicalldata,
                value: 0
            })
        );
        Iuniv3.multicall(calls)
        console.log("pool mint end");
    }
    {//flash creat
        let PairFlashinfo = {
            _swapRouter: "0xFE6508f0015C778Bdcc1fB5465bA5ebE224C9912",
            _factory: "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865",
            _WETH9: "0x4200000000000000000000000000000000000006"
        }
        let info = {
            cbETH: "0x2ae3f1ec7f1f5012cfeab0185bfc7aa3cf0dec22",
            weth: "0x4200000000000000000000000000000000000006",
        }
        var flashV3test = await ethers.deployContract("flashV3test", Object.keys(PairFlashinfo));
        let flashinput = {
            token0: USDA_add,
            token1: mek_add,
            fee1: fee,
            amount0: 10 ** 10,
            amount1: 0,
            fee2: fee,
            fee3: fee,
        }
        await flashV3test.stakein(
            flashinput
        )
    }

}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

