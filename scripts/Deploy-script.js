const hre = require("hardhat");

async function main() {

  const Lottery = await hre.ethers.getContractFactory("Lottery");
  const lottery = await Lottery.deploy("Hello, Hardhat!");

  await lottery.deployed();

  console.log("Greeter deployed to:", lottery.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
