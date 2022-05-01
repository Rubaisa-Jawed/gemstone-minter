const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GobletMinter", function () {
  let GobletMinter, gobletMinter, goblet;
  let owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, addr4, addr5, addr6] =
      await ethers.getSigners();
    GobletMinter = await ethers.getContractFactory("GobletMinter");
    gobletMinter = await GobletMinter.deploy();
    goblet = await ethers.getContractFactory("Gemstone");
    await goblet.deploy();
    await gobletMinter.deployed();
  });

  it("Should console the uri", async function () {
    console.log(await gobletMinter.connect(owner).uri(1));
  });
});
