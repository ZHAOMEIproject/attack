// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IPancakeV3Pool.sol';
import './interfaces/IQuoterV2.sol';
import './interfaces/IPancakeV3Factory.sol';

import './library/structinfo.sol';
import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
contract flashV3test is structinfo, Ownable{
    uint256 public immutable decimals=3;
    // // uint256 public immutable sil=1000-2;
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
        amountIn=
        stakeoutinfo_input.withdrawethbalance * 
        stakeoutinfo_input.multiplier/10**decimals;
        wiseamount=
        amountIn * 
        stakeoutinfo_input.limit_ethprice*stakeoutinfo_input.sil/10**(3+18);
        (
            amountOut,sqrtPriceX96After,,
        )=stakeoutinfo_input.quoter.quoteExactInputSingle(
            IQuoterV2.QuoteExactInputSingleParams(
                address(stakeoutinfo_input.CBETH),
                address(stakeoutinfo_input.WETH),
                amountIn,
                stakeoutinfo_input.fee,
                0
            )
        );
        flag=wiseamount<amountOut;
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
                    cWETHv3:params.cWETHv3,
                    stakein:true
                })
            )
        );
    }
    function stakeout(s_stakeoutinfo_input memory params)public {
        (uint256 amountIn,uint256 wiseamount,uint256 amountOut,uint160 sqrtPriceX96After,bool flag)
        =cbeth2ethprice(params);
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
                    cWETHv3:params.cWETHv3,
                    stakein:false
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
        if (data.stakein) {
            uint256 eth_need= uint256(IPancakeV3Pool(msg.sender).token0() == address(data.WETH) ? amount0Delta:amount1Delta);
            uint256 cbeth_bal= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.CBETH) ? amount0Delta:amount1Delta));


            // data.CBETH.transfer(data.origin, cbeth_bal);
            // data.cWETHv3.supplyFrom(data.origin,data.origin, address(data.CBETH), cbeth_bal);
            data.CBETH.approve(address(data.cWETHv3),type(uint256).max);
            data.cWETHv3.supplyTo(data.origin, address(data.CBETH), cbeth_bal);
            data.cWETHv3.withdrawFrom(data.origin,address(this),address(data.WETH),eth_need-data.ethbalance);

            data.WETH.deposit{value:data.ethbalance}();
            data.WETH.transfer(msg.sender,eth_need);
        } else {
            uint256 eth_need= uint256(-(IPancakeV3Pool(msg.sender).token0() == address(data.WETH) ? amount0Delta:amount1Delta));
            uint256 cbeth_bal= uint256((IPancakeV3Pool(msg.sender).token0() == address(data.CBETH) ? amount0Delta:amount1Delta));
            // data.WETH.transfer(data.origin, eth_need);
            // data.cWETHv3.supplyFrom(data.origin,data.origin, address(data.WETH), eth_need);

            data.WETH.approve(address(data.cWETHv3),type(uint256).max);
            data.cWETHv3.supplyTo(data.origin, address(data.WETH), (eth_need-data.ethbalance));
            data.cWETHv3.withdrawFrom(data.origin,msg.sender,address(data.CBETH),cbeth_bal);
            data.WETH.transfer(data.origin, data.ethbalance);

            // data.WETH.withdraw((data.ethbalance));
            // payable(msg.sender).transfer(data.ethbalance);
        }
    }
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function all(address add,bytes memory a,uint _gas,uint _value)public onlyOwner{
        (bool success,) = add.call{gas: _gas,value: _value}(a);
        require(success,"error call");
    }

}