//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/interfaces.sol";
import "../compound/CEther.sol";
import "../compound/CToken.sol";
import "hardhat/console.sol";

contract flash{
    address public owner;
    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    CToken cUSDC = CToken(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    CEther cETH = CEther(payable(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5));

    uint256 test_amount= 10**17;
    address v2pair=0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
    address v2router=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    constructor() payable{
        // owner=msg.sender;
        // IWETH(weth).deposit{value:1 ether}();
        // // uniswapV2Flash(bytes("0x01"));
        // uniswapV2Flash(new bytes(0));

    }
    function uniswapV2Flash(bytes memory data)public{
        address token0 = IUniswapV2pair(v2pair).token0();
        (uint amount0Out, uint amount1Out) = weth != token0 ? (uint(0), test_amount) : (test_amount, uint(0));
        console.log("address:",address(this));
        console.log("this (weth).balanceOf",IWETH(weth).balanceOf(address(this)));
        console.log("data.length",data.length);
        // IWETH(weth).transfer(v2pair, (test_amount*100301/100000));
        IUniswapV2pair(v2pair).swap(amount0Out, amount1Out, address(this),data);
    }
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external  {
        address token0 = IUniswapV2pair(v2pair).token0();
        uint256 amount = weth == token0 ?  amount0  : amount1;
        console.log(
            "IWETH(weth).balanceOf",IWETH(weth).balanceOf(address(this))
        );
        IWETH(weth).transfer(v2pair, amount*100301/100000);
    }
    function liquidity(address liqer)public payable{
        console.log(
            "liquidateBorrow befor cETH:",cETH.borrowBalanceStored(liqer),
            "cETH", cETH.balanceOf(liqer)
        );
        console.log(
            "cETH", cETH.balanceOf(address(this))
        );
        cETH.liquidateBorrow{value:msg.value}(liqer, cETH);
        console.log(
            "liquidateBorrow befor cETH:",cETH.borrowBalanceStored(liqer),
            "cETH", cETH.balanceOf(liqer)
        );
        console.log(
            "cETH", cETH.balanceOf(address(this))
        );
        console.log(
            "usdc balance:",usdc.balanceOf(address(this)),
            "usdc balance:",usdc.balanceOf(msg.sender)
        );
        // require(false,"test");
    }
    receive() external payable {}
}
