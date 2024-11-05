// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract USDA is EIP712 {
    constructor()EIP712("USDA", "1"){}
    
    function nonces(address owner) public pure returns (uint256) {
        owner;
        return 0;
    }
    struct permitinfo{
        address owner;
        address spender;
        uint value;
        uint deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    function t_permit(
        permitinfo memory _permit
    )public view returns(address signer){
        require(block.timestamp <= 
        _permit.deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
        _permit.owner, 
        _permit.spender, 
        _permit.value, 
        nonces(
        _permit.owner), 
        _permit.deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        signer = ecrecover(hash, 
        _permit.v, 
        _permit.r, 
        _permit.s);
    }
}
