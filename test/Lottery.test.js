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
        // Getting hardhat accounts
        [account1, account2] = await ethers.getSigners();

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [LINK_OWNER]
        });
        ownerLINK = await ethers.provider.getSigner(LINK_OWNER);
        await account2.sendTransaction({
            to: LINK_OWNER,
            value: ethers.utils.parseEther('10.0'),
        });
        ItokenLINK = await ethers.getContractAt("IERC20Upgradeable", LINK_ADDRESS);

        // Deploying mock VRF
        const FactoryVRF = await ethers.getContractFactory("VRFCoordinatorMock");
        VRFCoordinatorMock = await FactoryVRF.deploy(LINK_ADDRESS);
        VRFCoordinatorMock.deployed();

        // Deploying Lottery upgradeable
        const Lottery = await ethers.getContractFactory("Lottery");
        lottery = await upgrades.deployProxy(
            Lottery, 
            [
                VRFCoordinatorMock.address,
                LINK_ADDRESS,
                keyHash,
                ethers.utils.parseEther('0.1')
            ]
        );
        await lottery.deployed();

        // Passsing LINK to the Lottery
        let tx = await ItokenLINK.connect(ownerLINK).transfer(lottery.address, "10000000000000000000");
        tx = tx.wait();
    });
    it("Testing random number", async ()=>{
        // Requesting the number
        let tx = await lottery.getRandomNumber(234);
        tx = tx.wait();

        // Getting the requestId
        eventFilter = await lottery.filters.RequestedRandomness();
        event = await lottery.queryFilter(eventFilter, "latest");
        requestId = event[0].args.requestId;

        // Calling to get the Random
        tx = await VRFCoordinatorMock.callBackWithRandomness(requestId, "777", lottery.address);
        tx = tx.wait();

        const result = await lottery.randomResult();
        expect(result).to.be.equal(777);
    });
});
