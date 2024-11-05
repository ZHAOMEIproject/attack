// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WBTC is ERC20 {
    constructor() ERC20("WBTC", "WBTC") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}
