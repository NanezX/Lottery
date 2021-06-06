// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/CERC20.sol";
import "hardhat/console.sol";

contract Lottery is Initializable {
    uint fee;
    function initialize(uint256 _fee) public initializer {
        fee = _fee;
    }
}
