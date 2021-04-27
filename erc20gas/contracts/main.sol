// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20SnapshotEveryBlock.sol";
import "./impls/draft-ERC20Votes.sol";
import "./impls/draft-ERC20VotesLight.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address account, uint256 amount) external { _mint(account, amount); }
}

contract ERC20SnapshotEveryBlockMock is ERC20SnapshotEveryBlock {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address account, uint256 amount) external { _mint(account, amount); }
}

contract ERC20VotesMock is ERC20Votes {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {}
    function mint(address account, uint256 amount) external { _mint(account, amount); }
}

contract ERC20VotesLightMock is ERC20VotesLight {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {}
    function mint(address account, uint256 amount) external { _mint(account, amount); }
}
