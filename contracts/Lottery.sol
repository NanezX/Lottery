// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/CERC20.sol";
import "hardhat/console.sol";


contract Lottery is OwnableUpgradeable{
    uint256 public feeLottery;
    mapping(address => uint) tickets;
    uint256 result;

    event onNewSale(uint);
    event onNewWinner(address, uint);

    function initialize(uint256 _feeLottery) public initializer {
        feeLottery = _feeLottery;
    }



    function changeFee(uint _feeLottery) external onlyOwner{
        require(_feeLottery>=0 && _feeLottery<10000, "ERROR: INVALID_FEE");
        feeLottery=_feeLottery;
    }
}
