// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./otherinfo.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
// abstract 
abstract contract withdrawV2 is EIP712, otherinfo{
    constructor(
            uint256 _mini_amount,address _token,address _add_withdraw,string memory name, string memory version,
            address _withdraw,address _admin,address _manage,address _monitor
        )
        EIP712(
            name, version
        )
        otherinfo(
            _withdraw,_admin,_manage,_monitor
        )
        {
        set_info(_mini_amount,_token,_add_withdraw);
    }
    uint256 mini_amount;
    address token;
    address public add_withdraw;
    function set_info(uint256 _mini_amount,address _token,address _add_withdraw)public onlyRole(MANAGE_ROLE){
        mini_amount=_mini_amount;
        token=_token;
        add_withdraw=_add_withdraw;
    }

    bytes32 public constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 amount,uint256 orderid,uint256 deadline)");

    event e_Withdraw(address indexed sender,address indexed to,uint256 amount,uint256 indexed orderid);

    struct _signvrs{
        address spender;
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 orderid;
    }


    mapping(uint256=>bool) public orderids;
    function Withdraw_permit_auditor (
        _signvrs memory signinfo
    ) public  onlyRole(AUDITOR_ROLE) monitor_lock{
        if(orderids[signinfo.orderid]){
            return;
        }
        address auditor=msg.sender;
        uint256 deadline=signinfo.deadline;
        require(block.timestamp <= deadline, "LADT_WITHDRAW: expired deadline");
        address spender=signinfo.spender;
        uint256 amount=signinfo.amount;
        // 验证审核人员签名
        emit e_Withdraw(auditor,spender,amount,signinfo.orderid);
        address signer = signcheck(signinfo);
        // require(hasRole(WITHDRAW_ROLE,signer)&&signer==auditor, "LADT_WITHDRAW: auditor invalid signature");
        require(hasRole(WITHDRAW_ROLE,signer), "LADT_WITHDRAW: WITHDRAW_ROLE invalid signature");
        orderids[signinfo.orderid]=true;
        // 进行操作
        IERC20(token).transferFrom(add_withdraw,spender,amount);
    }

    struct _spenderinfo{
        address spender;
        uint256 amount;
        uint256 orderid;
    }

    function Withdraw_permit(
        _spenderinfo calldata spenderinfo
    ) public  onlyRole(WITHDRAW_ROLE) monitor_lock{
        require(spenderinfo.amount <= mini_amount, "LADT_WITHDRAW: error amount");
        if(orderids[spenderinfo.orderid]){
            return;
        }
        orderids[spenderinfo.orderid]=true;
        IERC20(token).transferFrom(add_withdraw,spenderinfo.spender,spenderinfo.amount);
        emit e_Withdraw(msg.sender,spenderinfo.spender,spenderinfo.amount,spenderinfo.orderid);
    }
    function lot_Withdraw_permit(
         _spenderinfo[] calldata spenderinfo
    )public onlyRole(WITHDRAW_ROLE) monitor_lock{
        for(uint i=0;i<spenderinfo.length;i++){
            Withdraw_permit(spenderinfo[i]);
        }
    }

    function lot_Withdraw_permit_auditor(
         _signvrs[] calldata spenderinfo
    )public onlyRole(AUDITOR_ROLE) monitor_lock{
        for(uint i=0;i<spenderinfo.length;i++){
            Withdraw_permit_auditor(spenderinfo[i]);
        }
    }

    function signcheck(
        _signvrs memory signinfo
    )public view returns(address signer){
        uint256 deadline=signinfo.deadline;
        // address auditor=signinfo.auditor;
        address spender=signinfo.spender;
        uint256 amount=signinfo.amount;
        uint256 orderid= signinfo.orderid;
        // 验证审核人员签名
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, spender, amount,orderid, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        return ECDSA.recover(hash, signinfo.v, signinfo.r, signinfo.s);
    }
    function all_signcheck(
        _signvrs memory signinfo
    )public view returns(address signer,bytes32 structHash,bytes32 hash){
        uint256 deadline=signinfo.deadline;
        // address auditor=signinfo.auditor;
        address spender=signinfo.spender;
        uint256 amount=signinfo.amount;
        uint256 orderid= signinfo.orderid;
        // 验证审核人员签名
        // bytes32 
        structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, spender, amount,orderid, deadline));
        // bytes32 
        hash = _hashTypedDataV4(structHash);
        signer=ECDSA.recover(hash, signinfo.v, signinfo.r, signinfo.s);
        // return ECDSA.recover(hash, signinfo.v, signinfo.r, signinfo.s);
    }
}