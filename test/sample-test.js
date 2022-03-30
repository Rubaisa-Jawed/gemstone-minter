const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GemstoneMinter", function () {
  let GemstoneMinter, gemstoneMinter, gemstone;
  let owner, addr1, addr2, addr3, addr4, addr5, addr6;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, addr4, addr5, addr6] =
      await ethers.getSigners();
    GemstoneMinter = await ethers.getContractFactory("GemstoneMinter");
    gemstoneMinter = await GemstoneMinter.deploy();
    gemstone = await ethers.getContractFactory("Gemstone");
    await gemstone.deploy();
    await gemstoneMinter.deployed();
  });

  it("Should print 2 different URIs", async function () {
    expect(await gemstoneMinter.getOwner()).to.equal(owner.address);

    const mintTx = await gemstoneMinter.mint(addr1.address, 1);
    await mintTx.wait();

    const uri = await gemstoneMinter.uri(101);

    const redeemTx = await gemstoneMinter.redeemGemstoneExperimental(
      addr1.address,
      101
    );
    await redeemTx.wait();

    const redeemedUri = await gemstoneMinter.uri(101);
    const mintTx2 = await gemstoneMinter.mint(addr1.address, 2);
    await mintTx2.wait();

    const uri2 = await gemstoneMinter.uri(200);
    console.log(uri2);

    expect(redeemedUri).to.not.equal(uri);
  });

  it("Should get purchases correctly", async function () {
    const mintTx = await gemstoneMinter.mint(addr1.address, 1);
    await mintTx.wait();

    const purchasesOfCust1 = await gemstoneMinter.getPurchasesOfCustomer(
      addr1.address
    );

    const mintTx2 = await gemstoneMinter.mint(addr2.address, 2);
    await mintTx2.wait();

    const purchasesOfCust2 = await gemstoneMinter.getPurchasesOfCustomer(
      addr1.address
    );

    const allPurchases = await gemstoneMinter.getAllPurchases();

    expect(purchasesOfCust1.length + purchasesOfCust2.length).to.equal(
      allPurchases.length
    );
  });

  //   it("Should whitelist an address", async function () {
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
  //   });

  //   it("Should whitelist address for different gemstones", async function () {
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
  //   });

  //   it("Should whitelist address for different gemstones", async function () {
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
  //   });

  //   it("Should fail as whitelist address already exists", async function () {
  //     await gemstoneMinter.addAddressToWhitelist(addr1.address, 1);
  //     await expect(
  //       gemstoneMinter.addAddressToWhitelist(addr1.address, 1)
  //     ).to.be.revertedWith("Address already in whitelist");
  //   });

  //   it("Should fail as Gemstone does not exist", async function () {
  //     await expect(
  //       gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 6)
  //     ).to.be.revertedWith("Gemstone does not exist");
  //   });

  //   it("Should allow a Whitelist Address to mint a Gemstone", async function () {
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
  //     await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 5);
  //     await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 5);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr3.address, 5);
  //     await gemstoneMinter.connect(addr3).whitelistMint(addr3.address, 5);
  //     await gemstoneMinter.connect(owner).addAddressToWhitelist(addr4.address, 5);
  //   });

  //   it("Should not allow a non Whitelist Address to mint a Gemstone", async function () {
  //     await expect(
  //       gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4)
  //     ).to.be.revertedWith(
  //       "Address does not have whitelist for this gemstone type"
  //     );
  //   });
});
