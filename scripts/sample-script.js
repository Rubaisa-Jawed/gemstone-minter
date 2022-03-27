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
  const GemstoneMinter = await hre.ethers.getContractFactory("GemstoneMinter");
  const gemstoneMinter = await GemstoneMinter.deploy();

  await gemstoneMinter.deployed();

  const mintTx = await gemstoneMinter.mint(
    "0xc2fBFf61209Bc2E13783Aac1268D6b76Ffa0D733",
    1
  );
  await mintTx.wait();

  console.log("GemstoneMinter deployed to:", gemstoneMinter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
