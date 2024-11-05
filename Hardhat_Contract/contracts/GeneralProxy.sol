// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// import "hardhat/console.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library StorageExt {
    struct AddressExt {
        address value;
    }
    function getAddressExt(bytes32 slot) internal pure returns (AddressExt storage r) {
        assembly {
            r.slot := slot
        }
    }
     function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
contract GeneralProxy{
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbb;
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    fallback() external {
       _fallback();
    }
    function _fallback() internal {
        address imp = StorageExt.getAddressExt(_IMPLEMENTATION_SLOT).value;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    function uploadTo(address imp) public {
        if(StorageExt.getAddressExt(_ADMIN_SLOT).value == msg.sender){
            require(StorageExt.isContract(imp)&&imp!=address(0));
            StorageExt.getAddressExt(_IMPLEMENTATION_SLOT).value = imp;
        }else{
            _fallback();
        }
    }
    constructor(address imp) {
        StorageExt.getAddressExt(_IMPLEMENTATION_SLOT).value = imp;
        StorageExt.getAddressExt(_ADMIN_SLOT).value = msg.sender;
    }
}
