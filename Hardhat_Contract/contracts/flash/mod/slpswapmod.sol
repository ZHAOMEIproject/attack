// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '../library/slp_structinfo.sol';
import '../interfaces/IPancakeV3Pool.sol';
import '../seamlessprotocol/interfaces/IPool.sol';

import "hardhat/console.sol";

contract slpswapmod is slp_structinfo{
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    address lockaddress=address(1);
    function _stakein(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )internal{
        SwapCallbackData memory data = abi.decode(
            abi.decode(_data, (opcodeAdata)).data, 
            (SwapCallbackData));
        uint256 eth_need= uint256(IPancakeV3Pool(msg.sender).token0() == address(data.WETH) ? amount0Delta:amount1Delta);
        uint256 cbeth_bal= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.CBETH) ? amount0Delta:amount1Delta));

        data.CBETH.approve(address(data.slp_WETH),type(uint256).max);
        IPool(address(data.slp_WETH)).supply(
            address(data.CBETH),
            cbeth_bal,
            lockaddress,
            0
        );
        IPool(address(data.slp_WETH)).borrow(
            address(data.WETH), 
            eth_need-data.ethbalance, 
            2, 
            0, 
            lockaddress
        );
        data.WETH.deposit{value:data.ethbalance}();
        data.WETH.transfer(msg.sender,eth_need);
    }
    function _stakeout(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )internal{
        SwapCallbackData memory data = abi.decode(
            abi.decode(_data, (opcodeAdata)).data, 
            (SwapCallbackData));
        uint256 eth_need= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.WETH) ? amount0Delta:amount1Delta));
        uint256 cbeth_bal= uint256((IPancakeV3Pool(msg.sender).token0() == address(data.CBETH) ? amount0Delta:amount1Delta));
        data.WETH.approve(address(data.slp_WETH),type(uint256).max);
        IPool(address(data.slp_WETH)).repay(
            address(data.WETH), 
            (eth_need-data.ethbalance), 
            2, 
            lockaddress
        );
        (address aTokenAddress,)=getdebttokenadd(data.slp_WETH,address(data.CBETH));
        IERC20 scbeth = IERC20(aTokenAddress);
        console.log(
            eth_need,
            cbeth_bal,
            scbeth.balanceOf(address(this)),
            scbeth.balanceOf(lockaddress)
        );
        scbeth.transferFrom(lockaddress,address(this),cbeth_bal);
        IPool(address(data.slp_WETH)).withdraw(
            address(data.CBETH), 
            cbeth_bal, 
            msg.sender
        );
        data.WETH.withdraw(data.WETH.balanceOf(address(this)));
        payable(lockaddress).transfer(address(this).balance);
    }
    function _one_changing_collateral(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )internal{
        // lock before_token
        one_changing_collateralDate memory data = abi.decode(
            abi.decode(_data, (opcodeAdata)).data, 
            (one_changing_collateralDate));
        //旧质押品
        uint256 before_token= uint256(IPancakeV3Pool(msg.sender).token0() == address(data.before_token) ? amount0Delta:amount1Delta);
        //新质押品
        uint256 after_token= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.after_token) ? amount0Delta:amount1Delta));
        IPool(address(data.slp_WETH)).supply(
            address(data.after_token),
            after_token,
            lockaddress,
            0
        );
        (address aTokenAddress,)=getdebttokenadd(data.slp_WETH,address(data.before_token));
        IERC20 scbeth = IERC20(aTokenAddress);
        scbeth.transferFrom(lockaddress,address(this),before_token);
        IPool(address(data.slp_WETH)).withdraw(
            address(data.before_token), 
            before_token, 
            msg.sender
        );
    }
    // function _twice_changing_collateral(
    //     int256 amount0Delta,
    //     int256 amount1Delta,
    //     bytes calldata _data
    // )internal{
    //     twice_changing_collateralDate memory data = abi.decode(_data, (twice_changing_collateralDate));
    //     //旧质押品
    //     uint256 before_token= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.before_token) ? amount0Delta:amount1Delta));
    //     //中间抵押品
    //     uint256 middle_token= uint256((IPancakeV3Pool(msg.sender).token0() == address(data.middle_token) ? amount0Delta:amount1Delta));

    //     IPancakeV3Factory factory=IPancakeV3Factory(data.quoter.factory());
    //     IPancakeV3Pool pool = IPancakeV3Pool(
    //         factory.getPool(
    //             address(data.middle_token),
    //             address(data.after_token),
    //             data.fee
    //     ));
    //     _data.stakein=3;
    //     pool.swap(
    //         address(this),
    //         address(data.middle_token)==pool.token0(),
    //         int256(middle_token),
    //         (address(data.middle_token)==pool.token0() ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1),
    //         abi.decode(_data, (SwapCallbackData))
    //     );
    // }
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
    modifier LOCK() {
        lockaddress=msg.sender;
        _;
        lockaddress=address(1);
    }

}