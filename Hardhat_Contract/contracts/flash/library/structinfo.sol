// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

contract structinfo{

    struct s_getstarkinfo_input{
        int24   tick;
        uint128 baseAmount;
        address baseToken;
        address quoteToken;

        uint256 ethbalance;
        uint256 multiplier;
        uint24 fee;
        uint256 limit_cbethprice;
        
        IQuoterV2 quoter;

    }
    struct SwapParams {
        address token0;
        address token1;
        uint24  fee;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
    }
    struct SwapCallbackData {
        uint256 amount0;
    }
    struct s_starkinfo{
        int24 tick,
        uint256 cbethprice;
        uint160 sqrtPriceLimitX96;

        

    }

}