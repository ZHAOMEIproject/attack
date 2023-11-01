// const { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack } = require('ethers/lib/utils');
const { keccak256, AbiCoder, toUtf8Bytes, solidityPacked } = require('ethers');
const solidityPack = solidityPacked;
const defaultAbiCoder = new AbiCoder();
// const { BigNumberish } = require('ethers');

const PERMIT_TYPEHASH = keccak256(
  toUtf8Bytes("Permit(address owner,address spender,uint256 amount,uint256 orderid,uint256 deadline)")
)

// Returns the EIP712 hash which should be signed by the user
// in order to make a call to `permit`
function getPermitDigest(
  name,
  address,
  chainId,
  params
) {
  const DOMAIN_SEPARATOR = getDomainSeparator(name, address, chainId)
  const structHash = keccak256(
    defaultAbiCoder.encode(
      ['bytes32', 'address', 'uint256', 'uint256', 'uint256'],
      [PERMIT_TYPEHASH, ...params]
    )
  );

  const endhash = keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        structHash
      ]
    )
  );
  // console.log(name, address, chainId);
  // console.log(DOMAIN_SEPARATOR);
  // console.log(structHash);
  // console.log(endhash);

  return endhash
}

// Gets the EIP712 domain separator
function getDomainSeparator(name, contractAddress, chainId) {
  return keccak256(
    defaultAbiCoder.encode(
      ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
      [
        keccak256(toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')),
        keccak256(toUtf8Bytes(name)),
        keccak256(toUtf8Bytes('1')),
        chainId,
        contractAddress,
      ]
    )
  )
}

module.exports = {
  getPermitDigest,
  getDomainSeparator
}