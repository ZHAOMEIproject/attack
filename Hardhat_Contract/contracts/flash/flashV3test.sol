// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './interfaces/IPancakeV3Factory.sol';
import './interfaces/IPancakeV3Pool.sol';
import './interfaces/IQuoterV2.sol';


import './library/univ3oracle.sol';
import './library/structinfo.sol';

import "hardhat/console.sol";
contract flashV3test is structinfo{
    function getstarkinfo(
        s_getstarkinfo_input memory getstarkinfo_input
    )public view returns(
        s_starkinfo memory starkinfo
    ){
        (starkinfo.tick,starkinfo.sqrtRatioX96)=univ3oracle.gettick(
            10**18,
            getstarkinfo_input.limit_cbethprice,
            getstarkinfo_input.baseToken,
            getstarkinfo_input.quoteToken
        );
        
        starkinfo.cbethprice=univ3oracle.getprice(
            getstarkinfo_input.tick,
            10**18,
            getstarkinfo_input.baseToken,
            getstarkinfo_input.quoteToken
        );

        (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32  initializedTicksCrossed,
            uint256 gasEstimate
        )=getstarkinfo_input.quoter.quoteExactInputSingle(
            getstarkinfo_input.baseToken,
            getstarkinfo_input.quoteToken,
            getstarkinfo_input.ethbalance * multiplier*99/100,
            getstarkinfo_input.fee,
            starkinfo.sqrtPriceLimitX96
        );
        require(
            amountOut> getstarkinfo_input.ethbalance * multiplier*starkinfo.cbethprice*99/100,
            "The price is too bad"
        );
    }
    function getamountout(uint256 amount_have,uint256 amount_keep,uint256 multiplier)public view returns(
        uint256 
        ){

    }
    function initSwap(SwapParams memory params) external {
        IPancakeV3Pool pool = IPancakeV3Pool(
            info.factory.getPool(
                params.token0,
                params.token1,
                params.fee
        ));
        
        pool.swap(
            address(this),
            params.token0==pool.token0(),
            params.amountSpecified,
            params.sqrtPriceLimitX96,
            abi.encode(
                SwapCallbackData({
                    amount0:100
                })
            )
        );
    }
    // function pancakeV3SwapCallback(
    //     int256 amount0Delta,
    //     int256 amount1Delta,
    //     bytes calldata data
    // ) external  {
    //     console.log("amount0Delta",amount0Delta);
    //     console.log("amount1Delta",amount1Delta);
    // }


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
}
