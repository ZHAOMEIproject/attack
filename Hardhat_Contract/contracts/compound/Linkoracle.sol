// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./PriceOracle.sol";
import "./CErc20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPriceFeed.sol";

contract Linkoracle is PriceOracle,Ownable {
    mapping(address => uint) prices;
    mapping(address => address) Oracle;
    event UpdateOracle(address asset, address Oracle);
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    error BadPrice();

    function _getUnderlyingAddress(CToken cToken) public view returns (address) {
        address asset;
        if (compareStrings(cToken.symbol(), "cETH")) {
            asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            asset = address(CErc20(address(cToken)).underlying());
        }
        return asset;
    }

    function getUnderlyingPrice(CToken cToken) public override view returns (uint) {
        uint decimal=18;
        if (_getUnderlyingAddress(cToken)!=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            decimal=CErc20(_getUnderlyingAddress(cToken)).decimals();
        }
        if (prices[_getUnderlyingAddress(cToken)]!=0) {
            return prices[_getUnderlyingAddress(cToken)]*10**(18-decimal);
        }
        (, int price, , , ) =  IPriceFeed(Oracle[_getUnderlyingAddress(cToken)]).latestRoundData();
        if (price <= 0) revert BadPrice();
        return uint256(price)*10**(18-decimal);
        // return uint256(price);
    }

    function setUnderlyingOracle(CToken cToken, address underlyingOracle) public onlyOwner  {
        address asset = _getUnderlyingAddress(cToken);
        emit UpdateOracle(asset, Oracle[asset]);
        Oracle[asset] = underlyingOracle;
    }

    function setDirectOracle(address asset, address underlyingOracle) public onlyOwner {
        emit UpdateOracle(asset, Oracle[asset]);
        Oracle[asset] = underlyingOracle;
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        uint decimal=18;
        if (asset!=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            decimal=CErc20(asset).decimals();
        }
        if (prices[asset]!=0) {
            return prices[asset]*10**(18-decimal);
        }
        (, int price, , , ) =  IPriceFeed(Oracle[asset]).latestRoundData();
        if (price <= 0) revert BadPrice();
        return uint256(price)*10**(18-decimal);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    

    function setUnderlyingPrice(CToken cToken, uint underlyingPriceMantissa) public onlyOwner {
        address asset = _getUnderlyingAddress(cToken);
        emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        prices[asset] = underlyingPriceMantissa;
    }

    function setDirectPrice(address asset, uint price) public onlyOwner {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }
}
