const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('GobletMinter', function () {
  let GobletMinter, gobletMinter, goblet;
  let owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, addr4, addr5, addr6] =
      await ethers.getSigners();
    GobletMinter = await ethers.getContractFactory('GobletMinter');
    gobletMinter = await GobletMinter.deploy();
    GemstoneMinter = await ethers.getContractFactory('GemstoneMinter');
    gemstoneMinter = await GemstoneMinter.deploy();
    goblet = await ethers.getContractFactory('Gemstone');
    await goblet.deploy();
    await gobletMinter.deployed();
    await gemstoneMinter.deployed();
  });

  it('Should console the uri', async function () {
    console.log(await gobletMinter.connect(owner).uri(1));
  });

  it('Should successfully mint a goblet', async function () {
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1);
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 2);
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 3);
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4);
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5);
    await gobletMinter.mintGoblet(addr1.address, gemstoneMinter.address);
  });

  it('Should fail to mint a goblet for an address that does not have 6 gemstones', async function () {
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1);
    await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
    await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5);
    await expect(
      gobletMinter.mintGoblet(addr1.address, gemstoneMinter.address)
    ).to.be.revertedWith('Not eligible to mint goblet');
  });

});
