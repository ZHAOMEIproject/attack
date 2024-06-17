// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '../interfaces/IQuoterV2.sol';
import '../interfaces/IPancakeV3Factory.sol';
import '../comp/CometMainInterface.sol';
import '../interfaces/IWETH.sol';
contract structinfo{
    struct s_stakeininfo_input{
        IWETH WETH;
        IERC20 CBETH;
        uint24 fee;
        uint256 multiplier;
        IQuoterV2 quoter;
        CometMainInterface cWETHv3;

        uint256 limit_cbethprice;
        uint256 sil;
    }
    struct s_stakeoutinfo_input{
        IWETH WETH;
        IERC20 CBETH;
        uint24 fee;
        uint256 multiplier;
        IQuoterV2 quoter;
        CometMainInterface cWETHv3;

        uint256 limit_ethprice;
        uint256 withdrawethbalance;
        uint256 sil;
    }

    struct SwapCallbackData {
        IWETH WETH;
        IERC20 CBETH;
        uint256 ethbalance;
        address origin;
        CometMainInterface cWETHv3;
        bool stakein;
    }
    struct s_swapinfo{
        uint256 amountIn;
        uint256 wiseamount;
        uint256 amountOut;
        uint160 sqrtPriceX96After;
        bool flag;
    }


}