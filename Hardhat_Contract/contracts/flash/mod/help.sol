// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract help is Ownable{
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