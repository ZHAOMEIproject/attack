// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IPancakeV3Pool.sol';
import './interfaces/IQuoterV2.sol';
import './interfaces/IPancakeV3Factory.sol';
import './library/slp_structinfo.sol';
import './mod/slpswapmod.sol';
import './mod/help.sol';
import "hardhat/console.sol";
contract slp_flashV3test is slpswapmod,help{
    uint256 public immutable decimals=4;
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
        wiseamount = amountOut*10**(decimals+18)/ 
        stakeoutinfo_input.limit_ethprice
        /stakeoutinfo_input.sil;
        (
            amountIn,sqrtPriceX96After,,
        )=stakeoutinfo_input.quoter.quoteExactOutputSingle(
            IQuoterV2.QuoteExactOutputSingleParams(
                address(stakeoutinfo_input.CBETH),
                address(stakeoutinfo_input.WETH),
                amountOut,
                stakeoutinfo_input.fee,
                0
            )
        );
        flag=wiseamount>amountIn;
    }
    function Ain2Bprice(
        s_twice_changeinfo_input memory twice_changeinfo_input
    ) public returns(uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160[] memory sqrtPriceX96AfterList,bool flag)
    {
        amountIn=
        twice_changeinfo_input.Ain;
        wiseamount=
        amountIn * twice_changeinfo_input.limitA2Bprice*twice_changeinfo_input.sil/10**(decimals+18);
        bytes memory path=encodePath(
            twice_changeinfo_input.tokens,
            twice_changeinfo_input.fees
        );
        (
            amountOut,sqrtPriceX96AfterList,,
        )=twice_changeinfo_input.quoter.quoteExactInput(
            path,
            amountIn
        );
        flag=wiseamount<amountOut;
        console.log(
            "amountOut: ", uint2str(amountOut), 
            "wish amount: ", uint2str(wiseamount)
        );
        require(flag,string(abi.encodePacked(
            "bad price",
            ", amountOut: ", uint2str(amountOut), 
            ", wish amount: ", uint2str(wiseamount)
        )));
    }

    function stakein(s_stakeininfo_input memory params)LOCK payable public {
        (uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160 sqrtPriceX96After,bool flag)
        =eth2cbethprice(params);
        require(flag,string(abi.encodePacked(
            "bad price",
            ", amountOut: ", uint2str(amountOut), 
            ", wish amount: ", uint2str(wiseamount)
        )));
        bytes memory data =abi.encode(
            opcodeAdata({
                stakein:1,
                data:
                abi.encode(SwapCallbackData({
                    WETH:params.WETH,
                    CBETH:params.CBETH,
                    ethbalance:msg.value,
                    slp_WETH:params.slp_WETH
                }))
            })
        );
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
            data
        );
    }
    function stakeout(s_stakeoutinfo_input memory params)LOCK public {
        (uint256 amountIn,uint256 wiseamount,,uint160 sqrtPriceX96After,bool flag)
        =cbeth2ethprice(params);
        require(flag,string(abi.encodePacked(
            "bad price",
            ", amountIn: ", uint2str(amountIn), 
            ", wish amount: ", uint2str(wiseamount)
        )));
        bytes memory data = abi.encode(
            opcodeAdata({
                stakein:0,
                data:
                abi.encode(SwapCallbackData({
                    WETH:params.WETH,
                    CBETH:params.CBETH,
                    ethbalance:params.withdrawethbalance,
                    slp_WETH:params.slp_WETH
                }))
            })
        );
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
            data
        );
        
    }
    function twice_changing_collateral(s_twice_changeinfo_input memory params)LOCK public{
        (uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160[] memory sqrtPriceX96AfterList,bool flag)
        =Ain2Bprice(params);
        (
            uint256 ethamount,,,
        )=params.quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams(
                address(params.tokens[0]),
                address(params.tokens[1]),
                amountIn,
                params.fees[0],
                0
            )
        );
        bytes memory data =abi.encode(
            opcodeAdata({
                stakein:3,
                data:
                abi.encode(twice_changing_collateralDate({
                    before_token:params.tokens[0],
                    middle_token:params.tokens[1],
                    after_token:params.tokens[2],
                    fee: params.fees[1],
                    quoter:params.quoter,
                    slp_WETH:params.slp_WETH,
                    Ain:amountIn
                }))
            })
        );
        
        IPancakeV3Factory factory=IPancakeV3Factory(params.quoter.factory());
        IPancakeV3Pool pool = IPancakeV3Pool(
            factory.getPool(
                address(params.tokens[1]),
                address(params.tokens[2]),
                params.fees[0]
        ));
        pool.swap(
            address(this),
            address(params.tokens[1])==pool.token0(),
            int256(ethamount),
            sqrtPriceX96AfterList[1],
            data
        );
    }
    function get_userinfo(s_twice_changeinfo_input memory params)public view returns(uint256 befortoken,uint256 aftertoken){
        twice_changing_collateralDate memory data = twice_changing_collateralDate({
            before_token:params.tokens[0],
            middle_token:params.tokens[1],
            after_token:params.tokens[2],
            fee: params.fees[1],
            quoter:params.quoter,
            slp_WETH:params.slp_WETH,
            Ain:0
        });
        (address aTokenAddress,)=getdebttokenadd(data.slp_WETH,data.before_token);
        (address bTokenAddress,)=getdebttokenadd(data.slp_WETH,data.after_token);
        befortoken = IERC20(aTokenAddress).balanceOf(msg.sender);
        aftertoken = IERC20(bTokenAddress).balanceOf(msg.sender);
        console.log(
            "befortoken: ",befortoken,
            "aftertoken: ",aftertoken
        );
    }

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
        opcodeAdata memory data = abi.decode(_data, (opcodeAdata));
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
        //  else if(data.stakein==2){
        //     _one_changing_collateral(
        //         amount0Delta,
        //         amount1Delta,
        //         _data
        //     );
        // }
         else if(data.stakein==3){
            _twice_changing_collateral(
                amount0Delta,
                amount1Delta,
                _data
            );
        }
        else if(data.stakein==4){
            if (amount0Delta>0) {
                IPancakeV3Pool pool = IPancakeV3Pool(msg.sender);
                IERC20(pool.token0()).transfer(msg.sender,uint256(amount0Delta));
            }else if(amount1Delta>0) {
                IPancakeV3Pool pool = IPancakeV3Pool(msg.sender);
                IERC20(pool.token1()).transfer(msg.sender,uint256(amount1Delta));
            }
        }

    }
    receive() external payable {
    }
    fallback() external payable {
    }
    function encodePath(
        address[] memory tokens,
        uint24[] memory fees
    ) internal pure returns (bytes memory path) {
        require(tokens.length == fees.length + 1, "Path: tokens and fees length mismatch");

        for (uint256 i = 0; i < fees.length; i++) {
            path = abi.encodePacked(path, tokens[i], fees[i]);
        }

        // Add the final token
        path = abi.encodePacked(path, tokens[tokens.length - 1]);
    }
}