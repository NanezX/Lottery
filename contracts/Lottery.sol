// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./interfaces/CERC20.sol";
import "hardhat/console.sol";
import "./upgradeables/VRFConsumerBaseUpgradeable.sol";

/// @title No loss lottery system in blockchain
/// @author Hernández, Victor; ...; ...
/// @notice This contract can be used to set a no loss lottery system. The users put their money
/// and will be deposited in pools to gain interest. A random number will get and all the interest
/// go to the winner.
/// @dev This contracts is upgradeable, so is necessary take in count that. The randomness is obtained
/// by oracles chainlink
contract Lottery is OwnableUpgradeable, VRFConsumerBaseUpgradeable{
    uint256 feeLottery;
    uint256 public randomResult;
    bytes32 keyHash;
    uint256 fee;
    uint256 numberRequest;
    mapping(address => uint) tickets;

    event RequestedRandomness(bytes32 indexed requestId, uint256 indexed numberRequest);
    event onNewSale(uint);
    event onNewWinner(address, uint);

    /// @notice Initialize the contract upgradeable
    /// @dev Here is setting all the features of the contract. Executed just in deploy, have 
    /// initializer.
    /// @param _feeLottery The fee that the contract get for each interest at the end of the lottery
    /// @param _vrfCoordinator The address of the VRF Chainlick Oracle where is get the Random number
    /// @param _link Address of LINK token
    /// @param _keyHash Keyhash used in the oracle to get the VRF
    /// @param _fee The fee used by the Oracle
    function initialize(
        uint _feeLottery,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint _fee) 
        public 
        initializer 
    {
        _init_VRF(_vrfCoordinator, _link);
        feeLottery = _feeLottery;
        keyHash = _keyHash;
        fee = _fee;
    }

    /// @notice Request a random number
    /// @dev The id is useful to track a correct request when is solicited a lot of this request
    /// @param userProvidedSeed A seed or number provide by the user
    /// @return requestId The ID of the request to track and get with the VRF
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
    receive() external payable {
        
    }
}
