// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./upgradeables/VRFConsumerBaseUpgradeable.sol";
import "./upgradeables/ChainlinkClientUpgradeable.sol";
import "./interfaces/CompoundInterfaces.sol";
import "./interfaces/IERC20.sol";
import "hardhat/console.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

/// @title No loss lottery system in blockchain
/// @author Hernández, Victor; ...; ...
/// @notice This contract can be used to set a no loss lottery system. The users put their money
/// and will be deposited in pools to gain interest. A random number will get and all the interest
/// go to the winner.
/// @dev This contracts is upgradeable, so is necessary take in count that. The randomness is obtained
/// by oracles chainlink
contract Lottery is OwnableUpgradeable, VRFConsumerBaseUpgradeable, ChainlinkClientUpgradeable {
    uint256 priceTicket;
    uint256 lotteryCounter;
    mapping(address => uint) tickets;
    struct Ticket {
        address owner;
        uint256 lotteryId;
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
        uint _pricePerTicket,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint _fee,
        address _oracle) 
        public 
        initializer 
    {
        __Ownable_init();
        priceTicket = _pricePerTicket; // 2$
        // VRF
        _init_VRF(_vrfCoordinator, _link);
        feeLottery = _feeLottery;
        keyHash = _keyHash;
        fee = _fee;

        // Chainlink
        _init_ChainlinkClient();
        // Oracle
        setChainlinkToken(_link);
        oraclePayment = _fee;
        oracle = _oracle; 
        jobId = "5348c2c08d03431a8872078bee96c6de";
        // Aggregator
        __init_aggregator();

        // Compound 
        __init_compound();
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

    // ---------------- Chainlink
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

    AggregatorV3Interface AggregatorETH;
    function __init_aggregator() public initializer {
        AggregatorETH = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    // Compound
    address[5] cTokens;

    function __init_compound() public initializer {
        cTokens[0] = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5; // cETH
        cTokens[1] = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // cDAI
        cTokens[2] = 0x12392F67bdf24faE0AF363c24aC620a2f67DAd86; // cTUSD
        cTokens[3] = 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // cUSDC
        cTokens[4] = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // cUSDT
    }

    function _setTicket(address buyer, uint amountTickets) internal {
        require(lotteryState == State.Selling, "Lottery running, must be wait");
    }
    

    function buyTickets(uint amountTickets, address tokenPayment, uint paymentType) public payable{
        require(paymentType >= 0 && paymentType <= 4, "ERROR: INVALID PAYMENT TYPE");
        if (paymentType == 0) {
            // Ether
            uint256 valueTickets = getPriceToTickets(amountTickets);
            require(msg.value >= valueTickets, "Not enough Ether to pay the amount of tickets");
            _supplyEthToCompound(cTokens[paymentType]);
        } else {
            // Tokens
            IERC20 Itoken = IERC20(tokenPayment);
            uint decimals = Itoken.decimals();
            uint valueTickets = amountTickets * priceTicket * 10**decimals;
            require(
                Itoken.allowance(msg.sender, address(this)) >= valueTickets,
                 "Not enough tokens to pay the amount of tickets"
            );
            Itoken.transferFrom(msg.sender, address(this), valueTickets);
            _supplyErc20ToCompound(Itoken, cTokens[paymentType], valueTickets);
        }
    }

    function getPriceToTickets(uint amountTickets) public view returns (uint){
        (, int price,,,) = AggregatorETH.latestRoundData();
        require(price > 0);
        return ((amountTickets * priceTicket * (10**8)) *  (10**18)) / uint(price);
    }

    function _supplyEthToCompound(address _cEthContract) internal {
        CEth cToken = CEth(_cEthContract);
        cToken.mint.value(msg.value).gas(250000)();
        console.log("Balance n:", cToken.balanceOf(address(this)));
        console.log("Balance Under:", cToken.balanceOfUnderlying(address(this)));
    }

    function _supplyErc20ToCompound(
        IERC20 _token,
        address _cErc20Contract,
        uint256 _amountTokensToSupply
    ) internal {
        CErc20 cToken = CErc20(_cErc20Contract);
        _token.approve(_cErc20Contract, _amountTokensToSupply);
        require(
            cToken.mint(_amountTokensToSupply) == 0,
             "Mint Result: ERROR"
        );
    }

    function redeemCErc20Tokens(uint256 _numToken) public {
        CErc20 cToken = CErc20(cTokens[_numToken]);
        uint256 amount = cToken.balanceOf(address(this));
        require(
            cToken.redeem(amount) == 0,
             "Redeem Result: ERROR"
        );
    }

   function redeemCEth() public {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(cTokens[0]);
        uint256 amount = cToken.balanceOf(address(this));
        console.log("Before redeem n: ", amount);
        console.log("Before redeem u: ", cToken.balanceOfUnderlying(address(this)));
        require(
            cToken.redeem(amount) == 0,
             "Redeem Result: ERROR"
        );
        console.log("After redeem n : ", cToken.balanceOf(address(this)));
        console.log("After redeem u : ", cToken.balanceOfUnderlying(address(this)));

    }
}
