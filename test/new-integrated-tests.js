const { expect } = require("chai");
const { ethers } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

const forwardTimeAYear = async () => {
    //Forward time by 1 year
    await ethers.provider.send("evm_increaseTime", [(366 * 24 * 3600) + 1]);
    await ethers.provider.send("evm_mine");
};
const forwardTimeAMonth = async () => {
    await ethers.provider.send("evm_increaseTime", [31 * 24 * 3600]);
    await ethers.provider.send("evm_mine");
}
const rewindTimeAYear = async () => {
    await ethers.provider.send("evm_increaseTime", [366 * 24 * 3600 * -1]);
    await ethers.provider.send("evm_mine");
}
const rewindTimeAMonth = async () => {
    await ethers.provider.send("evm_increaseTime", [31 * 24 * 3600 * -1]);
    await ethers.provider.send("evm_mine");
}

describe("Integrated tests", function () {
    let GemstoneMinter, gemstoneMinter, GobletMinter, gobletMinter;
    let owner, addr1, addr2, addr3, addr4, addr5, addr6;

    beforeEach(async function () {
        // deploy both contracts (gemstoneMinter & gobletMinter)
        [owner, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
        GobletMinter = await ethers.getContractFactory("GobletMinter");
        GemstoneMinter = await ethers.getContractFactory("GemstoneMinter");
        gemstoneMinter = await GemstoneMinter.deploy();
        gemstoneMinterAddress = gemstoneMinter.address
        gobletMinter = await GobletMinter.deploy();
        await gobletMinter.deployed();
        await gemstoneMinter.deployed();
        await forwardTimeAMonth();
        await forwardTimeAMonth();
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
        await rewindTimeAYear();
        // mint 1 as the owner
        await gobletMinter.connect(owner).ownerGobletMint();
        let uri = await gobletMinter.connect(addr1).uri(1);
        
        await expect(uri).to.equal("ipfs://QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj/1_2022.json");
    });

    it("Should let owner mint all 150 goblets, regardless of year or gemstones, and have all correct URIs.", async function () {
        for (let i = 0; i < 3; i++) {
            for (let i = 0; i < 50; i++) {
                await gobletMinter.connect(owner).ownerGobletMint();
            }      
            await forwardTimeAYear();      
        }
        await rewindTimeAYear();
        await rewindTimeAYear();
        await rewindTimeAYear();
        
        let gobletURI, uri2022, uri2023, uri2024;
        for (let i = 1; i < 151; i++) {
            ownerBalance = await gobletMinter.connect(owner).balanceOf(owner.getAddress(), i);
            expect(ownerBalance.toNumber()).to.equal(1);

            
            // checking all the URIs!
            gobletURI = await gobletMinter.connect(addr1).uri(i);

            // only console when needed for this test. 
            // console.log("Fetching goblet ID: ", i, " owned: ",  ownerBalance, " uri: ", gobletURI);

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
    it("Should allow a user to mint 6 gemstones, and mint a goblet every year", async function () {
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

        // mint a goblet in 2022 
        let callerGems = await gemstoneMinter.connect(addr1).isEligibleToMintGoblet(addr1.address);
        console.log(callerGems)

        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("FIRST GOBLET MINTED ------------------------------------------------");

        // console.log("Checking those gems again now! Should be 0s, because they've just been used.")
        // callerGems = await gemstoneMinter.connect(addr1).isEligibleToMintGoblet(addr1.address);
        
        // // testing isRedeemed on individual gemstones 
        // let isRedeemedBool; 
        // isRedeemedBool = await gemstoneMinter.connect(addr1).isGemRedeemedForId_REPLICA_TO_DELETE(1);
        // console.log("IS REDEEMED % ",isRedeemedBool);
        // isRedeemedBool = await gemstoneMinter.connect(addr1).isGemRedeemedForId_REPLICA_TO_DELETE(51);
        // console.log("IS REDEEMED % ",isRedeemedBool);
        // isRedeemedBool = await gemstoneMinter.connect(addr1).isGemRedeemedForId_REPLICA_TO_DELETE(101);
        // console.log("IS REDEEMED % ",isRedeemedBool);
        // console.log(callerGems)

        await expect(gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress)).to.be.reverted; // shouldn't be able to mint another one 
        
        
        // forward time 1 year 
        await forwardTimeAYear();
        await forwardTimeAMonth(); // forward 1 more month to get into the validity for the minting period
        // 2023, October 
        console.log("Minting for 2023 October");
        
        // checking the gems, which should be redeemable again 
        callerGems = await gemstoneMinter.connect(addr1).isEligibleToMintGoblet(addr1.address);
        console.log(callerGems)

        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("SECOND GOBLET MINTED ------------------------------------------------");

        await expect(gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress)).to.be.reverted; // make sure they can't mint additional goblets 
        
        // forward another year ()
        await forwardTimeAYear();
        // 2024, October 
        console.log("Minting for 2024 October");
        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("THIRD GOBLET MINTED ------------------------------------------------");
        await expect(gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress)).to.be.reverted; // try, should be reverted 

        let balance; 
        balance = await gobletMinter.connect(addr2).balanceOf(addr1.address, 1);
        console.log("BALANCE FOR ID 1: " + balance);
        balance = await gobletMinter.connect(addr2).balanceOf(addr1.address, 2);
        console.log("BALANCE FOR ID 2: " + balance);
        balance = await gobletMinter.connect(addr2).balanceOf(addr1.address, 3);
        console.log("BALANCE FOR ID 3: " + balance);
        // await expect(balance.toNumber()).to.equal(1);

        // reset the time 2 years back
        await rewindTimeAYear();
        await rewindTimeAYear();
    })

    // try minting 2 goblets with 12 gemstones, but should fail at minting 3 goblets, for all years
    it("Should not allow a user to mint more than 1 goblet per year", async function () {
        // whitelist for 6 gemstones 
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 4);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr1.address, 5);
        // whitelist addr2 for another 6 
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 0);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 1);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 2);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 3);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 4);
        await gemstoneMinter.connect(owner).addAddressToWhitelist(addr2.address, 5);
        // mint all 6 gemstones, both addresses 
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 0);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 1);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 2);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 3);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 4);
        await gemstoneMinter.connect(addr1).whitelistMint(addr1.address, 5);

        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 0);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 1);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 2);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 3);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 4);
        await gemstoneMinter.connect(addr2).whitelistMint(addr2.address, 5);
        // transfer the gemstonse from addr2 to addr1, so addr1 holds 12 valid gemstones 
        await gemstoneMinter.connect(addr2).safeTransferFrom(addr2.address, addr1.address, 2, 1, 0); // (gem ID #2, amount is 1)
        await gemstoneMinter.connect(addr2).safeTransferFrom(addr2.address, addr1.address, 52, 1,0); // (gem ID #52, amount is 1)
        await gemstoneMinter.connect(addr2).safeTransferFrom(addr2.address, addr1.address, 102, 1, 0); // (gem ID #102, amount is 1)
        await gemstoneMinter.connect(addr2).safeTransferFrom(addr2.address, addr1.address, 152, 1, 0); // (gem ID #152, amount is 1)
        await gemstoneMinter.connect(addr2).safeTransferFrom(addr2.address, addr1.address, 202, 1, 0); // (gem ID #202, amount is 1)
        await gemstoneMinter.connect(addr2).safeTransferFrom(addr2.address, addr1.address, 252, 1, 0); // (gem ID #252, amount is 1)
            
        let callerOwnedGems;
        // see the redeemable gemstones they have right now: 
        callerOwnedGems = await gemstoneMinter.connect(addr1).isEligibleToMintGoblet(addr1.address);
        console.log("CALLER OWNED GEMS !!! ---- FIRST MINT !");
        console.log(callerOwnedGems);

        // now try mint 3 goblets in 2022, only 2 should work
        // mint goblet 1!
        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("2022 MINT 1 SUCCESSFUL ****************************************");

        // See the redeemable gemstones now (should be 2, 52, etc.)
        callerOwnedGems = await gemstoneMinter.connect(addr1).isEligibleToMintGoblet(addr1.address);
        console.log("CALLER OWNED GEMS !!! ---- SECOND MINT !");
        console.log(callerOwnedGems);
        
        // mint goblet 2!
        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("2022 MINT 2 SUCCESSFUL ****************************************");

        // try mint goblet 3!
        await expect(gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress)).to.be.reverted; // try again, this should fail

        // after minting goblet, try and see if they've got eligible gemstones (they shouldn't)
        callerOwnedGems = await gemstoneMinter.connect(addr1).isEligibleToMintGoblet(addr1.address);
        console.log("CALLER OWNED GEMS (which should be invalid)");
        console.log(callerOwnedGems);

        // forward time 1 year 
        await forwardTimeAYear();
        // 2023

        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("2023 MINT 1 SUCCESSFUL ****************************************");

        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("2023 MINT 2 SUCCESSFUL ****************************************");

        await expect(gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress)).to.be.reverted; // try again, this should fail
        
        // forward 1 year 
        await forwardTimeAYear();
        // 2024 
        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("2024 MINT 1 SUCCESSFUL ****************************************");

        await gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress);
        console.log("2024 MINT 2 SUCCESSFUL ****************************************");

        await expect(gobletMinter.connect(addr1).mintGoblet(gemstoneMinterAddress)).to.be.reverted; // try again, this should fail

        let balance; 
        balance = await gobletMinter.connect(addr2).balanceOf(addr1.address, 1);
        console.log("BALANCE FOR ID 1: " + balance);
        balance = await gobletMinter.connect(addr2).balanceOf(addr1.address, 2);
        console.log("BALANCE FOR ID 2: " + balance);
        balance = await gobletMinter.connect(addr2).balanceOf(addr1.address, 3);
        console.log("BALANCE FOR ID 3: " + balance);
        await expect(balance.toNumber()).to.equal(1);


        console.log("LOGGING ALL GOBLET URIS");
        let uri; 
        uri = await gobletMinter.connect(addr3).uri(1);
        console.log(uri);
        uri = await gobletMinter.connect(addr3).uri(2);
        console.log(uri);
        uri = await gobletMinter.connect(addr3).uri(3);
        console.log(uri);
        uri = await gobletMinter.connect(addr3).uri(4);
        console.log(uri);
        uri = await gobletMinter.connect(addr3).uri(5);
        console.log(uri);
        uri = await gobletMinter.connect(addr3).uri(6);
        console.log(uri);
    })
});