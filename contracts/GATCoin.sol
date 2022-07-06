//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GATCoin is ERC20 {
    constructor(uint256 initialSupply) ERC20("Get a Token", "GAT") {
        _mint(msg.sender, initialSupply* 10**6);
    }
}