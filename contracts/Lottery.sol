// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/CERC20.sol";
import "hardhat/console.sol";
import "./upgradeables/VRFConsumerBaseUpgradeable.sol";


contract Lottery is OwnableUpgradeable, VRFConsumerBaseUpgradeable{
    uint256 public feeLottery;
    mapping(address => uint) tickets;
    uint256 public randomResult;
    bytes32 keyHash;
    uint256 fee;
    uint256 numberRequest;

    event RequestedRandomness(bytes32 requestId, uint256 indexed numberRequest);
    event onNewSale(uint);
    event onNewWinner(address, uint);

    function initialize(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint _fee) 
        public 
        initializer 
    {
        _init_VRF(_vrfCoordinator, _link);
        keyHash = _keyHash;
        fee = _fee;
    }


    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee, userProvidedSeed);
        emit RequestedRandomness(requestId, numberRequest);
        numberRequest++;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }


    function changeFee(uint _feeLottery) external onlyOwner{
        require(_feeLottery>=0 && _feeLottery<10000, "ERROR: INVALID_FEE");
        feeLottery=_feeLottery;
    }
}
