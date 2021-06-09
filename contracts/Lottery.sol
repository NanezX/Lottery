// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/CERC20.sol";
import "hardhat/console.sol";

contract Lottery is OwnableUpgradeable {
    uint fee;
    mapping(address => uint) tickets;
    address public admin;

    event onNewSale(uint);
    event onNewWinner(address, uint);

    function initialize(uint256 _fee, address _owner) public initializer {
        fee = _fee;
        admin = _admin
    }

    function buyTicket(uint amount) external {

    }


    function changeFee(uint _fee) external onlyOwner{
        require(_fee>=0 && _fee<10000, "ERROR: INVALID_FEE");
        fee=_fee;
    }
}
