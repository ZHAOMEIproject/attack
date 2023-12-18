//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface IUniswapV2pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
}
interface IUniswapV2Router{
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface ctoken{
    
}