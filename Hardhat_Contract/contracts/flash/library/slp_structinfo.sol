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
        IPool slp_WETH;
    }


    struct s_twice_changeinfo_input{
        address[] tokens;
        uint24[] fees;
        IQuoterV2 quoter;
        IPool slp_WETH;

        uint256 limitA2Bprice;
        uint256 Ain;
        uint256 sil;
    }

    struct twice_changing_collateralDate{
        address before_token;
        address after_token;
        uint24 fee;
        IQuoterV2 quoter;
        IPool slp_WETH;
        
        address middle_token;
        uint256 Ain;
    }



}