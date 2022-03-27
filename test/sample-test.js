const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GemstoneMinter", function () {
  it("Should execute", async function () {
    const [owner, addr1] = await ethers.getSigners();

    const GemstoneMinter = await ethers.getContractFactory("GemstoneMinter");
    const gemstoneMinter = await GemstoneMinter.deploy();
    await gemstoneMinter.deployed();
    expect(await gemstoneMinter.getOwner()).to.equal(owner.address);

    const mintTx = await gemstoneMinter.mint(addr1.address, 1);
    await mintTx.wait();

    const purchases = await gemstoneMinter.getPurchasesOfCustomer(
      addr1.address
    );
    //console.log(purchases);

    const uri = await gemstoneMinter.uri(101);
    console.log("non-redeemed", uri);

    const redeemTx = await gemstoneMinter.redeemGemstoneExperimental(
      addr1.address,
      101
    );
    await redeemTx.wait();

    const redeemedUri = await gemstoneMinter.uri(101);
    console.log("redeemed", redeemedUri);

    const mintTx2 = await gemstoneMinter.mint(addr1.address, 2);
    await mintTx2.wait();

    const uri2 = await gemstoneMinter.uri(200);
    console.log(uri2);
  });
});
