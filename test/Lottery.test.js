const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
// TOKEN ADDRESSES
const DAI_ADDRESS = "0x6b175474e89094c44da98b954eedeac495271d0f";
const USDC_ADDRESS = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
let USDT_ADDRESS;
let TUSD_ADDRESS;
let BUSD_ADDRESS;

// LINK TOKENT
const LINK_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
const LINK_OWNER = "0x98c63b7b319dfbdf3d811530f2ab9dfe4983af9d";

const keyHash = "0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445";

// Test variables
let ownerLINK, ItokenLINK, VRFCoordinatorMock, lottery;
let eventFilter, event, requestId;

describe("Lottery", function () {
    beforeEach(async ()=>{
        // Deploying mock VRF
        const FactoryVRF = await ethers.getContractFactory("VRFCoordinatorMock");
        VRFCoordinatorMock = await FactoryVRF.deploy(LINK_ADDRESS);
        VRFCoordinatorMock.deployed();

        // Deploying Lottery upgradeable
        const Lottery = await ethers.getContractFactory("Lottery");
        lottery = await upgrades.deployProxy(
            Lottery, 
            [
                500, // 5%
                VRFCoordinatorMock.address,
                LINK_ADDRESS,
                keyHash,
                ethers.utils.parseEther('0.1')
            ]
        );
        await lottery.deployed();

        // Getting hardhat accounts
        [account1, account2] = await ethers.getSigners();

        // Impersonating account that have a lot of LINK tokens and sending it some ether
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [LINK_OWNER]
        });
        ownerLINK = await ethers.provider.getSigner(LINK_OWNER);

        await account2.sendTransaction({
            to: LINK_OWNER,
            value: ethers.utils.parseEther('10.0'),
        });

        // Send ether to the Lottery Contract
        await account2.sendTransaction({
            to: lottery.address,
            value: ethers.utils.parseEther('10.0'),
        });


        // Passsing LINK to the Lottery
        ItokenLINK = await ethers.getContractAt("IERC20Upgradeable", LINK_ADDRESS);
        let tx = await ItokenLINK.connect(ownerLINK).transfer(lottery.address, "10000000000000000000");
        tx = await tx.wait();
    });
    it("Should return a random number from VRFCoordinator Mock", async ()=>{
        // Requesting the number
        let tx = await lottery.getRandomNumber(234);
        tx = await tx.wait();

        // Getting the requestId
        /*
        - filters: This get all the events "RequestedRandomness". Can set args to filter by indexeds
         - queryFilter: Get the event and search the latest. Btw, if the filter is unique (using args indexed),
         this method can search past events made by this contract 
        */
        eventFilter = await lottery.filters.RequestedRandomness(); 
        event = await lottery.queryFilter(eventFilter, "latest");
        requestId = event[0].args.requestId;

        // Calling to get the Random
        tx = await VRFCoordinatorMock.callBackWithRandomness(requestId, "777", lottery.address);
        tx = await tx.wait();

        const result = await lottery.lotteryResult();
        expect(result).to.be.equal(0); // 0 tickets sold so, the module of the random number is 0
    });
});
