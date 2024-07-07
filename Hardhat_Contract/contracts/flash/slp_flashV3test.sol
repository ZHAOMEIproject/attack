// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IPancakeV3Pool.sol';
import './interfaces/IQuoterV2.sol';
import './interfaces/IPancakeV3Factory.sol';
import './library/slp_structinfo.sol';
import './mod/slpswapmod.sol';
import './mod/help.sol';
import "hardhat/console.sol";
contract slp_flashV3test is slp_structinfo,slpswapmod,help{
    uint256 public immutable decimals=4;
    // constructor(s_stakeininfo_input memory params){
    //     stakein(params);
    //     selfdestruct(payable(msg.sender));
    // }
    function showstakeinfo(
        s_stakeininfo_input memory stakeininfo_input
    )public{
        (,uint256 wiseamount,uint256 amountOut,,bool flag)
        =eth2cbethprice(stakeininfo_input);
        require(
            flag,
            string(abi.encodePacked(
                "bad price",
                ", amountOut: ", uint2str(amountOut), 
                ", wish amount: ", uint2str(wiseamount)
            ))
        );
        require(
            flag,
            string(abi.encodePacked(
                "good price",
                ", amountOut: ", uint2str(amountOut), 
                ", wish amount: ", uint2str(wiseamount)
            ))
        );
    }
    function eth2cbethprice(
        s_stakeininfo_input memory stakeininfo_input
    )payable public returns(uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160 sqrtPriceX96After,bool flag)
    {
        amountIn=
        msg.value * 
        stakeininfo_input.multiplier/10**decimals;
        wiseamount=
        amountIn * 
        stakeininfo_input.limit_cbethprice*stakeininfo_input.sil/10**(decimals+18);
        (
            amountOut,sqrtPriceX96After,,
        )=stakeininfo_input.quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams(
                address(stakeininfo_input.WETH),
                address(stakeininfo_input.CBETH),
                amountIn,
                stakeininfo_input.fee,
                0
            )
        );
        flag=wiseamount<amountOut;
    }
    function cbeth2ethprice(
        s_stakeoutinfo_input memory stakeoutinfo_input
    ) public returns(uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160 sqrtPriceX96After,bool flag)
    {
        amountOut = 
        stakeoutinfo_input.withdrawethbalance* 
        stakeoutinfo_input.multiplier/10**decimals;
        
        wiseamount = amountOut* 
        stakeoutinfo_input.limit_ethprice*10**(decimals+18)/stakeoutinfo_input.sil;
        (
            amountIn,sqrtPriceX96After,,
        )=stakeoutinfo_input.quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams(
                address(stakeoutinfo_input.CBETH),
                address(stakeoutinfo_input.WETH),
                wiseamount,
                stakeoutinfo_input.fee,
                0
            )
        );
        flag=wiseamount>amountIn;
    }

    function stakein(s_stakeininfo_input memory params)payable public {
        (uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160 sqrtPriceX96After,bool flag)
        =eth2cbethprice(params);
        require(flag,string(abi.encodePacked(
            "bad price",
            ", amountOut: ", uint2str(amountOut), 
            ", wish amount: ", uint2str(wiseamount)
        )));
        IPancakeV3Factory factory=IPancakeV3Factory(params.quoter.factory());
        IPancakeV3Pool pool = IPancakeV3Pool(
            factory.getPool(
                address(params.WETH),
                address(params.CBETH),
                params.fee
        ));
        pool.swap(
            address(this),
            address(params.WETH)==pool.token0(),
            int256(amountIn),
            sqrtPriceX96After,
            abi.encode(
                SwapCallbackData({
                    WETH:params.WETH,
                    CBETH:params.CBETH,
                    ethbalance:msg.value,
                    origin:msg.sender,
                    slp_WETH:params.slp_WETH,
                    stakein:1
                })
            )
        );
    }
    function stakeout(s_stakeoutinfo_input memory params)public {
        (uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160 sqrtPriceX96After,bool flag)
        =cbeth2ethprice(params);
        console.log(
            amountIn,
            wiseamount,
            amountOut
        );
        require(false,"test");
        require(flag,string(abi.encodePacked(
            "bad price",
            ", amountOut: ", uint2str(amountOut), 
            ", wish amount: ", uint2str(wiseamount)
        )));
        IPancakeV3Factory factory=IPancakeV3Factory(params.quoter.factory());
        IPancakeV3Pool pool = IPancakeV3Pool(
            factory.getPool(
                address(params.WETH),
                address(params.CBETH),
                params.fee
        ));
        pool.swap(
            address(this),
            address(params.CBETH)==pool.token0(),
            int256(amountIn),
            sqrtPriceX96After,
            abi.encode(
                SwapCallbackData({
                    WETH:params.WETH,
                    CBETH:params.CBETH,
                    ethbalance:params.withdrawethbalance,
                    origin:msg.sender,
                    slp_WETH:params.slp_WETH,
                    stakein:0
                })
            )
        );
        
    }
    // function pancakeV3SwapCallback(
    function uniswapV3SwapCallback(
        int256          amount0Delta,
        int256          amount1Delta,
        bytes calldata  _data
    ) external  {
        _V3SwapCallback(
            amount0Delta,
            amount1Delta,
            _data
        );
    }
    function pancakeV3SwapCallback(
        int256          amount0Delta,
        int256          amount1Delta,
        bytes calldata  _data
    ) external  {
        _V3SwapCallback(
            amount0Delta,
            amount1Delta,
            _data
        );
    }
    function _V3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    )private{
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        if (data.stakein==1) {
            _stakein(
                amount0Delta,
                amount1Delta,
                _data
            );
        } else if (data.stakein==0) {
            _stakeout(
                amount0Delta,
                amount1Delta,
                _data
            );
        }

    }
    receive() external payable {
    }
    fallback() external payable {
        revert('Fallback not allowed');
    }
}