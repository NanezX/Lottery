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

describe("Lottery", function () {
    it("Testing random number", async ()=>{
        // Getting hardhat accounts
        [account1, account2] = await ethers.getSigners();

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [LINK_OWNER]
        });
        const ownerLINK = await ethers.provider.getSigner(LINK_OWNER);
        await account2.sendTransaction({
            to: LINK_OWNER,
            value: ethers.utils.parseEther('10.0'),
        });

        const ItokenLINK = await ethers.getContractAt("IERC20Upgradeable", LINK_ADDRESS);

        const factory = await ethers.getContractFactory("NumberRandom");
        const instanceNumber = await factory.deploy();
        await instanceNumber.deployed();

        let tx = await ItokenLINK.connect(ownerLINK).transfer(instanceNumber.address, ethers.utils.parseEther('2.0'));
        tx = tx.wait();

        expect(await instanceNumber.randomResult()).to.equal(0);
        
        
        


    });
});
