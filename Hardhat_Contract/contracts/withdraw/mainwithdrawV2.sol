// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.4;
import "./modular/withdrawV2.sol";
contract mainwithdrawV2 is withdrawV2{
    // add_withdraw is national treasury
    constructor(
        uint256 _mini_amount,address _token,address _add_withdraw,string memory name, string memory version,
        address _withdraw,address _admin,address _manage,address _monitor
    )
        withdrawV2(
            _mini_amount,_token,_add_withdraw,name,version,
            _withdraw,_admin,_manage,_monitor
        )
    {
        // _grantRole(AUDITOR_ROLE, 0x452Ae8BEc379698ff9106611865Ecf042AeE20D1);
        // _grantRole(AUDITOR_ROLE, 0x1E14589a0486aE6060A2eF966bE5702c998a6902);
        // _grantRole(AUDITOR_ROLE, 0xC66f6B7814B886aA104573FCe17862c2ce906740);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(MANAGE_ROLE, msg.sender);

        _grantRole(AUDITOR_ROLE, 0x67519FDb0A5374614F3ae454FEE2da5B1515CA06);
        _grantRole(WITHDRAW_ROLE, 0xa69EBF3984fD0c0bb49845860954C35081511903);
    }
}