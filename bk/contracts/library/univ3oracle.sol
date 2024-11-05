// SPDX-License-Identifier: AGPL
pragma solidity >=0.7.6;
import './TickMath.sol';
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
library univ3oracle{
    function getprice(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    )public  pure returns(uint256 quoteAmount){
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? MathUpgradeable.mulDiv(ratioX192, baseAmount, 1 << 192)
                : MathUpgradeable.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = MathUpgradeable.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? MathUpgradeable.mulDiv(ratioX128, baseAmount, 1 << 128)
                : MathUpgradeable.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
    function gettick(
        uint128 baseAmount,
        uint256 quoteAmount,
        address baseToken,
        address quoteToken
    )public  pure returns(int24 tick,uint160 sqrtRatioX96){
        uint256 ratioX192=baseToken < quoteToken
            ? ((1 << 192)/baseAmount)*quoteAmount
            : ((1 << 192)/quoteAmount)*baseAmount;
        sqrtRatioX96 = uint160(sqrt(ratioX192));
        tick = TickMath.getTickAtSqrtRatio(sqrtRatioX96);
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

