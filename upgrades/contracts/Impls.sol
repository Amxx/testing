// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract Impl1 is OwnableUpgradeable {
    string public name;
    string public description;

    function initialize(string calldata _name, string calldata _description) public virtual {
        __Ownable_init();
        name        = _name;
        description = _description;
    }
}

contract Impl2 is Impl1 {
    function setName(string calldata _name) public virtual onlyOwner() {
        name = _name;
    }
    function setDescription(string calldata _description) public virtual onlyOwner() {
        description = _description;
    }
}

contract Impl3 is Impl2 {
    string public uri;

    function setURI(string calldata _uri) public virtual onlyOwner() {
        uri = _uri;
    }
}

contract Impl1UUPS is Impl1, UUPSUpgradeable {
    function _authorizeUpgrade(address newImplementation) internal override {}
}

contract Impl2UUPS is Impl2, UUPSUpgradeable {
    function _authorizeUpgrade(address newImplementation) internal override {}
}

contract Impl3UUPS is Impl3, UUPSUpgradeable {
    function _authorizeUpgrade(address newImplementation) internal override {}
}
