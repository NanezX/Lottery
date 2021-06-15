const { ethers, upgrades, network } = require("hardhat");
const { expect } = require("chai");
const hre = require("hardhat");
const {time} = require("@openzeppelin/test-helpers");
const { latestBlock } = require("@openzeppelin/test-helpers/src/time");

// TOKEN ADDRESSES
const DAI_ADDRESS = "0x6b175474e89094c44da98b954eedeac495271d0f";
const USDT_ADDRESS = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const USDC_ADDRESS = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
const TUSD_ADDRESS = "0x0000000000085d4780B73119b644AE5ecd22b376";
const BUSD_ADDRESS = "0x4fabb145d64652a948d72533023f6e7a623c7c53";

// LINK TOKENT
const LINK_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
const LINK_OWNER = "0x98c63b7b319dfbdf3d811530f2ab9dfe4983af9d";

const keyHash = "0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445";

// Test variables
let ownerLINK, ItokenLINK, VRFCoordinatorMock, mockOracle, lottery;
let eventFilter, event, requestId, tx;
const data = "0x0000000000000000000000000000000000000000000000000000000000000000";

describe("Lottery", function () {
    beforeEach(async ()=>{
        // Getting hardhat accounts
        [account1, account2] = await ethers.getSigners();
        
        // Deploying mock VRF
        const FactoryVRF = await ethers.getContractFactory("VRFCoordinatorMock");
        VRFCoordinatorMock = await FactoryVRF.deploy(LINK_ADDRESS);
        VRFCoordinatorMock.deployed();

        // Deploying mock Oracle
        const MockOracle = await ethers.getContractFactory("MockOracle");
        mockOracle = await MockOracle.deploy(LINK_ADDRESS);
        mockOracle.deployed();

        // Deploying Lottery upgradeable
        const Lottery = await ethers.getContractFactory("Lottery");
        lottery = await upgrades.deployProxy(
            Lottery, 
            [
                500, // 5%
                VRFCoordinatorMock.address,
                LINK_ADDRESS,
                keyHash,
                ethers.utils.parseEther('0.1'),
                mockOracle.address
            ]
        );
        await lottery.deployed();


        // Impersonating account that have a lot of LINK tokens and sending it some ether
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [LINK_OWNER]
        });
        ownerLINK = await ethers.provider.getSigner(LINK_OWNER);

        await account2.sendTransaction({
            to: LINK_OWNER,
            value: ethers.utils.parseEther('5.0'),
        });

        // Send ether to the Lottery Contract
        await account2.sendTransaction({
            to: lottery.address,
            value: ethers.utils.parseEther('5.0'),
        });

        // Passsing LINK to the Lottery
        ItokenLINK = await ethers.getContractAt("IERC20Upgradeable", LINK_ADDRESS);
        let tx = await ItokenLINK.connect(ownerLINK).transfer(lottery.address, "10000000000000000000");
        tx = await tx.wait();
    });
    it("Should change the lottery State", async ()=>{
        
    });
});

/*      //Increase time
        await hre.network.provider.send("evm_increaseTime", [
            Number(time.duration.minutes(10)),
        ]);
        // Mine
        await hre.network.provider.send("evm_mine");

        Filter an event
        eventFilter = await lottery.filters.RequestedRandomness(); 
        event = await lottery.queryFilter(eventFilter, "latest");
        requestId = event[0].args.requestId;

        Make a response of VRF
        tx = await VRFCoordinatorMock.callBackWithRandomness(requestId, "666", lottery.address);
        tx = await tx.wait();

        Make a response of Oracle to Alarm Clock
        tx = await mockOracle.fulfillOracleRequest(requestId, data);
        tx = await tx.wait();
*/
