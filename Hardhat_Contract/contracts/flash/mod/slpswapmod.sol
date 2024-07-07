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
        
        data.CBETH.approve(address(data.slp_WETH),type(uint256).max);
        IPool(address(data.slp_WETH)).supply(
            address(data.CBETH),
            cbeth_bal,
            data.origin,
            0
        );
        IPool(address(data.slp_WETH)).borrow(
            address(data.WETH), 
            eth_need-data.ethbalance, 
            2, 
            0, 
            data.origin
        );
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
        data.WETH.approve(address(data.slp_WETH),type(uint256).max);
        IPool(address(data.slp_WETH)).repay(
            address(data.WETH), 
            (eth_need-data.ethbalance), 
            2, 
            data.origin
        );
        (address aTokenAddress,)=getdebttokenadd(data.slp_WETH,address(data.CBETH));
        IERC20 scbeth = IERC20(aTokenAddress);
        console.log("test");
        console.log(
            eth_need,
            cbeth_bal,
            scbeth.balanceOf(address(this)),
            scbeth.balanceOf(data.origin)
        );
        scbeth.transferFrom(data.origin,address(this),cbeth_bal);
        console.log("test");
        IPool(address(data.slp_WETH)).withdraw(
            address(data.CBETH), 
            cbeth_bal, 
            msg.sender
        );
        console.log("test");
        data.WETH.withdraw(data.WETH.balanceOf(address(this)));
        payable(data.origin).transfer(address(this).balance);
    }
    function _changing_collateral(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )internal{
        // changing_collateralDate memory data = abi.decode(_data, (changing_collateralDate));
        // //旧质押品
        // uint256 before_token= uint256(IPancakeV3Pool(msg.sender).token0() == address(data.before_token) ? amount0Delta:amount1Delta);
        // //中间媒介或新质押品
        // uint256 after_token= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.after_token) ? amount0Delta:amount1Delta));

        // if(address(data.middle_token)==address(0)){
        //     IPool(address(data.slp_WETH)).supply(
        //         address(data.after_token),
        //         after_token,
        //         data.origin,
        //         0
        //     );
        //     data.scbeth.transferFrom(data.origin,address(this),cbeth_bal);
        //     IPool(address(data.slp_WETH)).withdraw(
        //         address(data.CBETH), 
        //         cbeth_bal, 
        //         msg.sender
        //     );
        // }else{

        // }

        
    }
    function getdebttokenadd(IPool slp_WETH,address token)public view returns(
        address aTokenAddress,
        address variableDebtTokenAddress
    ){
        DataTypes.ReserveData memory result =slp_WETH.getReserveData(token);
        return (
            result.aTokenAddress,
            result.variableDebtTokenAddress
        );
    }
}