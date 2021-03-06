// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/IComp.sol";
import "openzeppelin-solidity/contracts/utils/Arrays.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

abstract contract ERC20Votes is IComp, ERC20Permit {
    bytes32 private constant _DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => address) private _delegates;
    mapping (address => uint256[]) private _checkpointBlocks;
    mapping (address => mapping (uint256 => uint256)) private _checkpointWeights;

    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * Example: This enables autodelegation, makes each transfer more expensive but doesn't require user to delegate to
     * themselves. Can be usefull for tokens useds exclusivelly for governance, such as voting wrappers of pre-existing
     * ERC20.
     */
    // function delegates(address account) public view override returns (address) {
    //     address delegatee = _delegates[account];
    //     return delegatee == address(0) ? account : delegatee;
    // }

    function getCurrentVotes(address account) external view override returns (uint256) {
        uint256 pos = _checkpointBlocks[account].length;
        return pos == 0 ? 0 : _checkpointWeights[account][pos - 1];
    }

    function getPriorVotes(address account, uint blockNumber) external view override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes::getPriorVotes: not yet determined");
        uint256 pos = Arrays.findUpperBound(_checkpointBlocks[account], blockNumber);
        return pos == 0 ? 0 : _checkpointWeights[account][pos - 1];
    }

    function delegate(address delegatee) public virtual override {
        return _delegate(_msgSender(), delegatee);
    }

    function delegateFromBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s)
    public virtual override
    {
        require(block.timestamp <= expiry, "ERC20Votes::delegateBySig: signature expired");
        address signatory = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(
                _DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            ))),
            v, r, s
        );
        require(nonce == _useNonce(signatory), "ERC20Votes::delegateBySig: invalid nonce");
        return _delegate(signatory, delegatee);
    }

    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) private {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = _checkpointBlocks[srcRep].length;
                uint256 srcRepOld = srcRepNum > 0 ? _checkpointWeights[srcRep][srcRepNum - 1] : 0;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = _checkpointBlocks[dstRep].length;
                uint256 dstRepOld = dstRepNum > 0 ? _checkpointWeights[dstRep][dstRepNum - 1] : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 pos, uint256 oldWeight, uint256 newWeight) private {
      if (pos > 0 && _checkpointBlocks[delegatee][pos - 1] == block.number) {
          _checkpointWeights[delegatee][pos - 1] = newWeight;
      } else {
          _checkpointBlocks[delegatee].push(block.number);
          _checkpointWeights[delegatee][pos] = newWeight;
      }

      emit DelegateVotesChanged(delegatee, oldWeight, newWeight);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        _moveDelegates(delegates(from), delegates(to), amount);
    }
}
