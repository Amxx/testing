// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/IComp.sol";
import "openzeppelin-solidity/contracts/utils/Arrays.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

abstract contract ERC20VotesLight is IComp, ERC20Permit {
    struct Checkpoint {
        uint32  block;
        uint224 weight;
    }

    bytes32 private constant _DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping (address => address) private _delegates;
    mapping (address => Checkpoint[]) private _checkpoints;

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
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].weight;
    }

    function getPriorVotes(address account, uint blockNumber) external view override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes::getPriorVotes: not yet determined");

        uint256 high = _checkpoints[account].length;
        uint256 low = 0;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (_checkpoints[account][mid].block > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && _checkpoints[account][low - 1].block == blockNumber) {
            return _checkpoints[account][low - 1].weight;
        } else {
            return _checkpoints[account][low].weight;
        }
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
                uint256 srcRepNum = _checkpoints[srcRep].length;
                uint256 srcRepOld = srcRepNum == 0 ? 0 : _checkpoints[srcRep][srcRepNum - 1].weight;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = _checkpoints[dstRep].length;
                uint256 dstRepOld = dstRepNum == 0 ? 0 : _checkpoints[dstRep][dstRepNum - 1].weight;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 pos, uint256 oldWeight, uint256 newWeight) private {
      if (pos > 0 && _checkpoints[delegatee][pos - 1].block == block.number) {
          _checkpoints[delegatee][pos - 1].weight = uint224(newWeight); // TODO: test overflow ?
      } else {
          _checkpoints[delegatee].push(Checkpoint({
              block: uint32(block.number),
              weight: uint224(newWeight)
          }));
      }

      emit DelegateVotesChanged(delegatee, oldWeight, newWeight);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        _moveDelegates(delegates(from), delegates(to), amount);
    }
}
