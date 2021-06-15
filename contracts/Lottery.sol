// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";
import "./upgradeables/VRFConsumerBaseUpgradeable.sol";
import "./upgradeables/ChainlinkClientUpgradeable.sol";

/// @title No loss lottery system in blockchain
/// @author Hernández, Victor; ...; ...
/// @notice This contract can be used to set a no loss lottery system. The users put their money
/// and will be deposited in pools to gain interest. A random number will get and all the interest
/// go to the winner.
/// @dev This contracts is upgradeable, so is necessary take in count that. The randomness is obtained
/// by oracles chainlink
contract Lottery is OwnableUpgradeable, VRFConsumerBaseUpgradeable, ChainlinkClientUpgradeable {

    uint256 lotteryCounter;
    mapping(address => uint) tickets;
    struct Ticket {
        address owner;
    }
    uint256 ticketsSold;

    /// @notice Return the lotteryResult
    /// @dev lotteryResult come from Oracle VRF chainlink
    uint256 public lotteryResult;

    enum State { Selling, Collecting }
    State public lotteryState;
    
    // VRF
    uint256 feeLottery;
    bytes32 keyHash;
    uint256 fee;

    // Chainlink client
    uint256 private oraclePayment;
    address private oracle;
    bytes32 private jobId;

    /// @notice An event that is emitted when a request for a random numer is made
    event RequestedRandomness(bytes32 indexed requestId, uint256 indexed lotteryCounter);

    /// @notice Event that is emitted when a new lottery start
    event NewStart(bytes32 indexed reqId, uint256 indexed lotteryCounter);

    /// @notice Event that is emitted when a lottey has been finished
    event buyClosed(bytes32 indexed reqId, uint256 indexed lotteryCounter, uint256 ticketsSold);

    /// @notice An event that is emitted when to 
    event NumberWinner(uint256 indexed result, bytes32 indexed requestId, uint256 indexed lotteryCounter);

    /// @notice The receive eth by default
    /// @dev Receive will be activated if some ether come to the contracts without or bad calldata 
    receive() external payable {
        
    }

    /// @notice Change the fee on the interest at the lottery
    /// @dev Must be [0-10000]
    /// @param _feeLottery The fee that the contract get for each interest at the end of the lottery
    function changeFee(uint _feeLottery) external onlyOwner{
        require(_feeLottery>=0 && _feeLottery<10000, "ERROR: INVALID_FEE");
        feeLottery=_feeLottery;
    }

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
        uint _fee,
        address _oracle) 
        public 
        initializer 
    {
        __Ownable_init();
        // VRF
        _init_VRF(_vrfCoordinator, _link);
        feeLottery = _feeLottery;
        keyHash = _keyHash;
        fee = _fee;

        // Chainlink client
        _init_ChainlinkClient();
        // Oracle
        setChainlinkToken(_link);
        oraclePayment = _fee;
        oracle = _oracle; 
        jobId = "5348c2c08d03431a8872078bee96c6de";
    }

    // ---------------- VRF
    /// @notice Request a random number
    /// @dev The id is useful to track a correct request when is solicited a lot of this request
    /// @param userProvidedSeed A seed or number provide by the user
    /// @return requestId The ID of the request to track and get with the VRF
    function getRandomNumber(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee, userProvidedSeed);
        emit RequestedRandomness(requestId, lotteryCounter);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // lotteryResult = randomness % (ticketsSold + 1); Uncomment this when set the right lottery system
        lotteryResult = randomness;
        emit NumberWinner(lotteryResult, requestId, lotteryCounter);
        lotteryCounter++;
    }

    // ---------------- Chainlink client
    function start() external onlyOwner {
        require(lotteryCounter == 0 && lotteryState == State.Selling);
        bytes32 reqId = _chainLinkRequest(this.closeBuy.selector, 2 days);
        lotteryState = State.Selling;
        emit NewStart(reqId, lotteryCounter);
    }

    function newStart(bytes32 _requestId) public recordChainlinkFulfillment(_requestId){
        bytes32 reqId = _chainLinkRequest(this.closeBuy.selector, 2 days);
        lotteryState = State.Selling;
        emit NewStart(reqId, lotteryCounter);
    }

    function closeBuy(bytes32 _requestId) public recordChainlinkFulfillment(_requestId) {
        getRandomNumber(lotteryCounter);
        lotteryState = State.Collecting;
        bytes32 reqId = _chainLinkRequest(this.newStart.selector, 5 days);
        emit buyClosed(reqId, lotteryCounter, ticketsSold);
    }

    function _chainLinkRequest(bytes4 _selector, uint256 _time) internal returns(bytes32){
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), _selector);
        req.addUint("until", block.timestamp + _time);
        bytes32 reqId = sendChainlinkRequestTo(oracle, req, oraclePayment);
        return reqId;
    }
}
