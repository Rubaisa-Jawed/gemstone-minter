const { expect } = require("chai");
const { ethers } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

describe("Integrated tests", function () {
    let GemstoneMinter, gemstoneMinter, GobletMinter, gobletMinter;
    let owner, addr1, addr2, addr3, addr4, addr5, addr6;

    beforeEach(async function () {
        // deploy both contracts (gemstoneMinter & gobletMinter)
        [owner, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
        GobletMinter = await ethers.getContractFactory("GobletMinter");
        GemstoneMinter = await ethers.getContractFactory("GemstoneMinter");
        gemstoneMinter = await GemstoneMinter.deploy();
        gobletMinter = await GobletMinter.deploy();
        await gobletMinter.deployed();
        await gemstoneMinter.deployed();
    });


    // BASIC GEMSTONE TESTS -------------------------------------------------------------------------------------------------------------------------------------------

    // whitelist an address & mint a gemstone to an address
    it("Should whitelist & mint gemstone 1 to an address", async function () {   
        console.log(addr1.address);
        // whitelist them for the first gemstone 
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
        let balance = await gemstoneMinter.connect(addr2).balanceOf(addr1.address, 1);
        console.log(balance.toNumber());
        await expect(balance.toNumber()).to.equal(1)
    })
    
    // try mint to non-whitelisted address 
    it("Should block gemstone minting to non-whitelisted address", async function () {
        await expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0)).to.be.reverted;
    })
    
    // try to whitelist address via non-owner address 
    it("Should not allow non-owner address to whitelist", async function () {
        await expect(gemstoneMinter.connect(addr1).addAddressToWhitelist(addr2.address, 0)).to.be.reverted;
    });

    // try to whitelist a gem type non-owner is not whitelisted for
    it("Should not allow address to mint without being whitelisted for a particular gem type", async function () {
        await expect(gemstoneMinter.connect(addr2).whitelistMint(addr1.address, 0)).to.be.reverted;
    })

    // try to double mint each gemstone 
    it("Should not allow double minting of gemstones of any type", async function () {
        // whitelist address for all 6
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
        // try mint all 6, the first time 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 2);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 3);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5);
        // try mint all 6 again 
        expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0)).to.be.reverted;
        expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1)).to.be.reverted;
        expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 2)).to.be.reverted;
        expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 3)).to.be.reverted;
        expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4)).to.be.reverted;
        expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5)).to.be.reverted;
    });


    // LARGE GEMSTONE TESTS -------------------------------------------------------------------------------------------------------------------------------------------

    // whitelist an address for 5 gemstones, and have the non-owner address try mint all 6
    it("Should not allow minting for more gemstones than address is whitelisted for", async function () {
        testFailed = false; 
        // whitelist 
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
        // mint
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 2);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 3);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4);
        await expect(gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5)).to.be.reverted;
        
        // check the balances all match up correctly
        let balance; 
        balance = await gemstoneMinter.connect(addr3).balanceOf(addr1.address, 1);
        expect (balance.toNumber()).to.equal(1);
        balance = await gemstoneMinter.connect(addr3).balanceOf(addr1.address, 51);
        expect (balance.toNumber()).to.equal(1);
        balance = await gemstoneMinter.connect(addr3).balanceOf(addr1.address, 101);
        expect (balance.toNumber()).to.equal(1);
        balance = await gemstoneMinter.connect(addr3).balanceOf(addr1.address, 151);
        expect (balance.toNumber()).to.equal(1);
        balance = await gemstoneMinter.connect(addr3).balanceOf(addr1.address, 201);
        expect (balance.toNumber()).to.equal(1);
        balance = await gemstoneMinter.connect(addr3).balanceOf(addr1.address, 251);
        expect (balance.toNumber()).to.equal(0);
    });

    // whitelist 3 different addresses, for all 6 gemstones, mint all 6 to each address. 
    it("Should whitelist 3 different addresses for all gemstones and mint 6 to each address", async function () {
        // whitelist 
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr3.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr3.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr3.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr3.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 4);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr3.address, 4);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 5);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr3.address, 5);
        // mint all gemstones 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 0);
        await gemstoneMinter.connect(addr3).whitelistMint(addr3.address, 0); 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 1);
        await gemstoneMinter.connect(addr3).whitelistMint(addr3.address, 1); 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 2);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 2);
        await gemstoneMinter.connect(addr3).whitelistMint(addr3.address, 2); 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 3);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 3);
        await gemstoneMinter.connect(addr3).whitelistMint(addr3.address, 3); 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 4);
        await gemstoneMinter.connect(addr3).whitelistMint(addr3.address, 4); 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 5);
        await gemstoneMinter.connect(addr3).whitelistMint(addr3.address, 5); 
        // no errors thrown, all good.
    });


    // GOBLET TESTS ---------------------------------------------------------------------------------------------------------------------------------------------

    // mint goblet as the owner & output the correct URI 
    it("Should mint a goblet to the owner", async function () {
        // mint 1 as the owner
        await gobletMinter.connect(owner).ownerGobletMint();
        let uri = await gobletMinter.connect(addr1).uri(1);
        
        await expect(uri).to.equal("ipfs://QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj/1_2022.json");
    });

    it("Should let owner mint all 150 goblets, regardless of year or gemstones, and have all correct URIs.", async function () {
        for (let i = 0; i < 150; i++) {
            await gobletMinter.connect(owner).ownerGobletMint();
        }
        
        let gobletURI, uri2022, uri2023, uri2024;
        for (let i = 1; i < 151; i++) {
            ownerBalance = await gobletMinter.connect(owner).balanceOf(owner.getAddress(), i);
            expect(ownerBalance.toNumber()).to.equal(1);

            
            // checking all the URIs!
            gobletURI = await gobletMinter.connect(addr1).uri(i);

            // only console when needed for this test. 
            console.log("Fetching goblet ID: ", i, " owned: ",  ownerBalance, " uri: ", gobletURI);

            uri2022 = ("ipfs://QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj/" + i + "_2022.json");
            uri2023 = ("ipfs://QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj/" + i + "_2023.json");
            uri2024 = ("ipfs://QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj/" + i + "_2024.json");
            if (i < 51) {
                expect(gobletURI).to.equal(uri2022);
            } else if (i < 101) {
                expect(gobletURI).to.equal(uri2023);
            } else {
                expect(gobletURI).to.equal(uri2024);
            }
        }
    })

    // try update the CID to something random, and update again
    it("Should update CID successfully.", async function () {
        await gobletMinter.connect(owner).ownerGobletMint();
        testFailed = false;
        // change CID first
        await gobletMinter.connect(owner).updateCID("fooBarCID24y242");
        let newUri = await gobletMinter.connect(owner).uri(1);
        if (newUri != "ipfs://fooBarCID24y242/1_2022.json") {
            testFailed = true;
        }
        console.log(newUri);
        // restore original
        await gobletMinter.connect(owner).updateCID("QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj");
        newUri = await gobletMinter.connect(addr2).uri(1);
        if (newUri != "ipfs://QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj/1_2022.json") {
            testFailed = true;
        }
        console.log(newUri);
        expect(testFailed).to.equal(false);
    });

    // try update CID as non-owner address
    it("Should block non-owners from changing CID", async function () {
        await expect(gobletMinter.connect(addr1).updateCID("testing_this")).to.be.reverted;
    })

    // try ownerMint a goblet as a non-owner 
    it("Should block non-owners from using ownerGobletMint()", async function () {
        await expect(gobletMinter.connect(addr1).ownerGobletMint()).to.be.reverted;
    });

    // COMBINED END-TO-END TESTS ------------------------------------------------------------------------------------------------------------------------

    // mint all 6 gemstones, as a non-owner, and mint the goblet, every year, for 3 years
    it("Should allow a user to mint 6 gemstones, and mint a goblet", async function () {
        // whitelist for 6 gemstones 
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
        // mint all 6 gemstones 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 2);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 3);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5);
        // mint a goblet 
        await gobletMinter.connect(addr1).mintGoblet();

        let balance; 
        balance = await gobletMinter.connect(addr2).balanceOf(addr1.address, 1);
        await expect(balance.toNumber()).to.equal(1);
    })
    // mi
});