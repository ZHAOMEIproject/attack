// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
contract Imputation {
    address immutable public owner;
    WalletProxy public Proxycontract;
    constructor(address treasury){
        owner=treasury;
        Proxycontract=new WalletProxy(address(new Walletlogic(treasury)));
    }
    function getwalletadd(uint256 path)public view returns(address walletadd){
        unchecked{
            bytes32 salt = keccak256(abi.encodePacked(path));
            bytes memory creationCode="0x3d602d80600a3d3981f3363d3d373d3d3d363d733c563092e25d7b597d97fccf3cc25f5387104a7b5af43d82803e903d91602b57fd5bf3000000000000000000";
            address implementation=address(Proxycontract);
            creationCode=abi.encodePacked(
                bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
                implementation,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );
            return address(uint160(uint(keccak256(abi.encodePacked(
                    bytes1(0xff),
                    address(this),
                    salt,
                    keccak256(creationCode)
                )))));
        }
    }
    function imputationtoken(uint256[] calldata paths,IERC20 token)public {
        unchecked{
            for (uint256 i; i<paths.length; i++) {
                address n_add = getwalletadd(paths[i]);
                if(token.balanceOf(n_add)==0){
                    continue ;
                }
                if(n_add.codehash ==0){
                    clone(paths[i]);
                }
                Walletlogic(n_add).imputationtoken(token);
                // WalletProxy(n_add).imputationtoken(token);
            }
        }
    }
    function clone(uint256 path) private returns (address instance) {
        address implementation=address(Proxycontract);
        bytes32 salt = keccak256(abi.encodePacked(path));
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37,salt)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
    function changeProxy(address implementation)public{
        Proxycontract.upgradeTo(implementation);
    }
}
contract Walletlogic{
    address immutable public owner;
    constructor(address treasury) {
        owner=treasury;
    }
    function imputationtoken(IERC20 token)public{
        token.transfer(owner,token.balanceOf(address(this)));
    }
    function all(address add,bytes calldata a,uint256 _gas,uint256 _value)payable public {
        unchecked {
            (bool success,) = add.call{gas: _gas,value: _value}(a);
            require(success,"error call");
        }
    }
}
contract  WalletProxy is Initializable, Proxy, ERC1967Upgrade,Ownable {
    address  immutable public thisaddress=address(this);
    constructor(address _logic) payable {
        _disableInitializers();
        _upgradeTo(_logic);
    }

    function _implementation() internal view virtual override returns (address impl) {
        return WalletProxy(payable(thisaddress)).implementation();
        // return ERC1967Upgrade._getImplementation();
    }
    function implementation() public view returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
    function upgradeTo(address _logic)public onlyOwner {
        _upgradeTo(_logic);
    }
}