async function main() {
    const LINK_ADDRESS = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
    const LINK_OWNER = "0x98c63b7b319dfbdf3d811530f2ab9dfe4983af9d";

    const admin = "0xbF334f8BD1420a1CbFE15407f73919424934B1B3";

    // Passsing LINK to the Lottery
    const ItokenLINK = await ethers.getContractAt("IERC20Upgradeable", LINK_ADDRESS);
    const balance= await ItokenLINK.balanceOf(LINK_OWNER);
    console.log(balance);

    const FactoryVRF = await ethers.getContractFactory("VRFCoordinatorMock");
    console.log("Deploying...");
    const VRFCoordinatorMock = await FactoryVRF.deploy(LINK_ADDRESS);
    console.log("Deploying address: ", VRFCoordinatorMock.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });