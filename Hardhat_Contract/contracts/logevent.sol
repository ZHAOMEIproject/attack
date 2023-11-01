// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./compound/CErc20.sol";

contract logevent is ERC20Upgradeable,OwnableUpgradeable{
    CErc20 ctoken;
    function set_comp(CErc20 _ctoken)  public onlyOwner {
        ctoken=_ctoken;
    }
    event Log_mint_to(uint256 orderid,address to, uint256 amount);
    event Log_mint(uint256 orderid, uint256 amount);
    event Log_burn(uint256 orderid, uint256 amount);
    // bool[] public orderids["mint_to"];
    // bool[] public orderids["mint"];
    // bool[] public orderids["burn"];
    // bool[] public orderids["comp_mint"]["mint"];
    // bool[] public orderids["comp_withdraw"];
    mapping(string=>mapping(uint256=>bool)) orderids;
    function log_mint_to(uint256 orderid,address to, uint256 amount)  public onlyOwner {
        require(!orderids["mint_to"][orderid],"Order duplication");
        _mint(to, amount);
        emit Log_mint_to(orderid,to, amount);
        orderids["mint_to"][orderid]=true;
    }
    function log_mint(uint256 orderid, uint256 amount)  public onlyOwner {
        require(!orderids["mint"][orderid],"Order duplication");
        _mint(msg.sender, amount);
        emit Log_mint(orderid, amount);
        orderids["mint"][orderid]=true;
    }
    function log_burn(uint256 orderid, uint256 amount)  public onlyOwner {
        require(!orderids["burn"][orderid],"Order duplication");
        _burn(msg.sender, amount);
        emit Log_burn(orderid, amount);
        orderids["burn"][orderid]=true;
    }

    event Log_comp_mint(uint256 orderid, uint256 n_token, uint256 out_ctoken);
    event Log_comp_withdraw(uint256 orderid, uint256 n_ctoken, uint256 out_token);

    function log_comp_mint(uint256 orderid,uint256 n_token)  public onlyOwner {
        require(!orderids["comp_mint"][orderid],"Order duplication");
        _transfer(msg.sender, address(this), n_token);
        uint256 old_balanceof=ctoken.balanceOf(address(this));
        _approve(address(this), address(ctoken), n_token);
        ctoken.mint(n_token);
        uint256 out_ctoken=ctoken.balanceOf(address(this))-old_balanceof;
        ctoken.transfer(msg.sender, out_ctoken);
        emit Log_comp_mint(orderid,n_token,out_ctoken);
        orderids["comp_mint"][orderid]=true;
    }
    function log_comp_withdraw(uint256 orderid,uint256 n_ctoken)  public onlyOwner {
        require(!orderids["comp_withdraw"][orderid],"Order duplication");
        uint256 old_balanceof=balanceOf(address(this));
        require(ctoken.transferFrom(msg.sender, address(this), n_ctoken),"error transferFrom");
        ctoken.redeem(n_ctoken);
        uint256 out_token=balanceOf(address(this))-old_balanceof;
        _transfer(address(this), msg.sender,out_token);
        emit Log_comp_withdraw(orderid,n_ctoken,out_token);
        orderids["comp_withdraw"][orderid]=true;
    }
}