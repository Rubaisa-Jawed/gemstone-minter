// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  console.log("Deploying GemstoneMinter");
  const GemstoneMinter = await hre.ethers.getContractFactory("GemstoneMinter");
  const gemstoneMinter = await GemstoneMinter.deploy();

  await gemstoneMinter.deployed();

  console.log("GemstoneMinter deployed to:", gemstoneMinter.address);

  console.log("Deploying GobletMinter");
  const GobletMinter = await hre.ethers.getContractFactory("GobletMinter");
  const gobletMinter = await GobletMinter.deploy();

  await gobletMinter.deployed();


  // await gemstoneMinter.addAddressToWhitelist(
  //   "0xc2fBFf61209Bc2E13783Aac1268D6b76Ffa0D733",
  //   1
  // );

  // const mintTx = await gemstoneMinter.whitelistMint(
  //   "0xc2fBFf61209Bc2E13783Aac1268D6b76Ffa0D733",
  //   0
  // );
  // await mintTx.wait();

  console.log("Everything seems to have happened correctly");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
