// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";
contract NFT1155 is ERC1155, Ownable {
    constructor(IWRAP warp) ERC1155("") Ownable(msg.sender) {
        _wrap = warp;
        _mint(msg.sender, 4, 2200, "");
        _mint(msg.sender, 3, 5500, "");
        _mint(msg.sender, 2, 8800, "");
        _mint(msg.sender, 1, 13200,"");
        _mint(msg.sender, 0, 22000,"");
        _baseURI="ipfs://bafybeick54wfmdtym5ad7z6pas22xsktraq6ar47wwl6eok42kyxqg6qbm/";
        name="Finexia";
        symbol="Finexia";
    }
    string public symbol;
    string public name;
    string public _baseURI;

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId),".json"));
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId),".json"));
	}
	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}


    IWRAP private _wrap;
    modifier onlywrap() {
        require(msg.sender == address(_wrap), "DENIED");
        _;
    }
    function wrap_burn(address account, uint256 id, uint256 value) public onlywrap {
        _burn(account, id, value);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public override virtual  {
        from;to;ids;values;data;
        return;
    }
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public override virtual {
        super.safeTransferFrom(
            from,to,id,value,data
        );
        _wrap.nft1155_transfer(from,to,id,value);
    }
}

interface IWRAP {
    function nft1155_transfer(
        address from,address to,uint256 tokenid,uint256 value
    ) external;
}