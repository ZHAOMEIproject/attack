// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '../interfaces/IQuoterV2.sol';
import '../interfaces/IPancakeV3Factory.sol';
import '../comp/CometMainInterface.sol';
import '../interfaces/IWETH.sol';
import '../seamlessprotocol/interfaces/IPool.sol';

contract slp_structinfo{
    struct s_stakeininfo_input{
        IWETH WETH;
        IERC20 CBETH;
        uint24 fee;
        uint256 multiplier;
        IQuoterV2 quoter;
        IPool slp_WETH;

        uint256 limit_cbethprice;
        uint256 sil;
    }
    struct s_stakeoutinfo_input{
        IWETH WETH;
        IERC20 CBETH;
        uint24 fee;
        uint256 multiplier;
        IQuoterV2 quoter;
        IPool slp_WETH;

        uint256 limit_ethprice;
        uint256 withdrawethbalance;
        uint256 sil;
    }

    struct opcodeAdata {
        uint256 stakein;
        bytes data;
    }

    struct SwapCallbackData {
        IWETH WETH;
        IERC20 CBETH;
        uint256 ethbalance;
        address origin;
        IPool slp_WETH;
    }



    struct one_changing_collateralDate{
        IERC20 before_token;
        IERC20 after_token;
        uint24 fee;
        IQuoterV2 quoter;
        IPool slp_WETH;

        uint256 b2aPricelimit;
        address origin;
    }
    struct twice_changing_collateralDate{
        IERC20 before_token;
        IERC20 after_token;
        uint24 fee;
        IQuoterV2 quoter;
        IPool slp_WETH;

        uint256 b2aPricelimit;
        address origin;
        
        IERC20 middle_token;
    }



}