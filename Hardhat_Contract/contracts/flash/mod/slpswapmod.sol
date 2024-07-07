// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '../library/slp_structinfo.sol';
import '../interfaces/IPancakeV3Pool.sol';
import '../seamlessprotocol/interfaces/IPool.sol';
import "hardhat/console.sol";

contract slpswapmod is slp_structinfo{
    function _stakein(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )internal{
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        uint256 eth_need= uint256(IPancakeV3Pool(msg.sender).token0() == address(data.WETH) ? amount0Delta:amount1Delta);
        uint256 cbeth_bal= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.CBETH) ? amount0Delta:amount1Delta));

        data.CBETH.approve(address(data.cWETHv3),type(uint256).max);
        IPool(address(data.cWETHv3)).supply(
            address(data.CBETH),
            cbeth_bal,
            data.origin,
            0
        );
        data.scbeth.transfer(data.origin,data.scbeth.balanceOf(address(this)));
        console.log("test");
        IPool(address(data.cWETHv3)).borrow(
            address(data.WETH), 
            eth_need-data.ethbalance, 
            2, 
            0, 
            data.origin
        );
        console.log("test");
        data.WETH.deposit{value:data.ethbalance}();
        data.WETH.transfer(msg.sender,eth_need);
    }
    function _stakeout(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )internal{
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        uint256 eth_need= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.WETH) ? amount0Delta:amount1Delta));
        uint256 cbeth_bal= uint256((IPancakeV3Pool(msg.sender).token0() == address(data.CBETH) ? amount0Delta:amount1Delta));
        // data.WETH.transfer(data.origin, eth_need);
        // data.cWETHv3.supplyFrom(data.origin,data.origin, address(data.WETH), eth_need);

        data.WETH.approve(address(data.cWETHv3),type(uint256).max);

        // data.cWETHv3.supplyTo(data.origin, address(data.WETH), (eth_need-data.ethbalance));
        // data.cWETHv3.withdrawFrom(data.origin,msg.sender,address(data.CBETH),cbeth_bal);
        // data.WETH.transfer(data.origin, data.ethbalance);

        IPool(address(data.cWETHv3)).repay(
            address(data.WETH), 
            (eth_need-data.ethbalance), 
            2, 
            data.origin
        );
        data.scbeth.transferFrom(data.origin,address(this),cbeth_bal);
        IPool(address(data.cWETHv3)).withdraw(
            address(data.WETH), 
            cbeth_bal, 
            data.origin
        );
        data.WETH.withdraw((data.ethbalance));
        (bool success, ) = msg.sender.call{value: data.ethbalance}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
}