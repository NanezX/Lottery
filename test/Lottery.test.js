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
const LINK_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA";

// TOKEN OWNERS
const DAI_OWNER = "0x16463c0fdb6ba9618909f5b120ea1581618c1b9e";
const USDT_OWNER = "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503";
const USDC_OWNER = "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503";
const TUSD_OWNER = "0x3ddfa8ec3052539b6c9549f12cea2c295cff5296";
const BUSD_OWNER = "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503";
const LINK_OWNER = "0x98c63b7b319dfbdf3d811530f2ab9dfe4983af9d";


// Test variables
const data = "0x0000000000000000000000000000000000000000000000000000000000000000";
const keyHash = "0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445";

let VRFCoordinatorMock, mockOracle, lottery;
let eventFilter, event, requestId, tx;

// Tokens variables
let ItokenLINK, ItokenDAI, ItokenUSDT, ItokenUSDC, ItokenTUSD, ItokenBUSD;
let ownerLINK, ownerDAI, ownerUSDT, ownerUSDC, ownerTUSD, ownerBUSD;

// Compound
// const COMP = "0xc00e94cb662c3520282e6f5717214004a7f26888";
// const Comptroller = "0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b";
// const cDAI = "0x5d3a536e4d6dbd6114cc1ead35777bab948e3643";
// const cETH = "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5";
// const cTUSD = "0x12392f67bdf24fae0af363c24ac620a2f67dad86";
// const cUSDC = "0x39aa39c021dfbae8fac545936693ac917d5e7563";
// const cUSDT = "0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9";
// const cUSDT = "0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9";

describe("Lottery", function () {
    beforeEach(async ()=>{
        // Getting hardhat accounts
        [account1, account2, account3] = await ethers.getSigners();
        
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
