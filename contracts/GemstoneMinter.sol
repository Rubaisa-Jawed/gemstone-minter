//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Gemstone.sol";
import {Types} from "./libs/Types.sol";

contract GemstoneMinter is Gemstone, ERC1155 {
    //This is for opensea contract name display
    string public name = "Malt, Grain & Cane Infinity Gemstones";
    string public unredeemedMetadataCID = "QmYn21JY4tgB7EN35z11papkWG2YqyNdqiZJDN78zh8hYc";
    string public redeemedMetadataCID = "QmaUzAyJ5hrovGtPdVg9ZQTjo1Q2ZYU7ztZ1SQG3C6Z26D";

    constructor() ERC1155("") {
        console.log("Init GemstoneMinter success");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    //function for adding address to whitelist for specific gemstone types
    function addAddressToWhitelist(
        address customerAddress,
        uint256 gemstoneType
    ) public onlyOwner {
        addToWhitelist(customerAddress, gemstoneType);
    }

    /*
        Mark as purchased the gemstone for address
        @param customerAddress address of customer
        @param gemstoneType gemstone type
        Range of gemstone type is defined in Types.sol (0..5)
        Sets redeemed as false by default
        The mint id is by series of increasing id, matching the metadata
        0-50 for gemstone type 0
        100-150 for gemstone type 1
        ...
    */
    //function for whitelist minting
    function whitelistMint(address customerAddress, uint256 gemstoneType)
        public
        payable
    {
        //check if whitelist exists for this gemstone type
        require(
            isCustomerWhiteListed(customerAddress, gemstoneType),
            "Address does not have whitelist for this gemstone type"
        );

        //check if gemstone is available for minting
        require(isGemstoneAvailable(gemstoneType), "Gemstone not available");

        //check if gemstone type has been minted by a specific customeraddress (to avoid customers doubling minting the same type)
        require(
            !isGemstoneMinted(customerAddress, gemstoneType),
            "Gemstone already minted"
        );

        // Record minting of gemstone in mappings 
        // (purchases, purchasesByGemstone, redeemedList)
        uint256 gemId = recordPurchase(customerAddress, gemstoneType); // NOTE: gemId is only 1-50 for each gemstone type
        uint256 mintId = gemstoneType * 50 + gemId; // NOTE: mintId is 1-300, for all gemstones. 

        //Set redeemed as false by default
        // addToRedeemedWithDefault(mintId); (not needed)

        //Mint
        _mint(customerAddress, mintId, 1, "");
    }

    /* 
        NEW ELIGIBILITY CHECKING FUNCTION
        Returns if the user has 6 gemstones redeemable
        Redeemable is true in 2 conditions
        1. The gemstone is not redeemed
        2. The gemstone is redeemed but past the validity period
        This function is here, not in gemstone.sol because it requires the use of `balanceOf`, which is inherited from the ERC1155 openzepplin contract.
        @param callerAdrress caller address (passed as parameter, not msg.sender, because function may be called by goblet.sol contract)
        @returns 6 valid gemstones (one of each type) or 0 if not eligible to mint a goblet
    */
    function isEligibleToMintGoblet(address callerAddress) public view returns (uint16[6] memory callerOwnedValidGems) {

        // firstly, find which gemstones the caller owns by running BalanceOf() through all NFT IDs (1-300) 
        // unfortunately while inefficient, this is the only option that makes sense in this scenario. 
        uint16[300] memory callerOwnedGems; 
        uint NFTsCount = 0;
        for (uint16 i = 1; i < 301; i++) {
            if ((balanceOf(callerAddress, i)) > 0) {
                // if token balance > 0, the caller has the NFT with ID `i` 
                callerOwnedGems[NFTsCount] = i; // store the ID of the NFT 
                NFTsCount ++;
            }
        }

        // check they have at least 6 gemstones (otherwise stop further logic)
        require(NFTsCount > 5, "You don't have enough gemstones to redeem for a goblet");

        // if they have 6, check they're at least one of each type 

        // ints to store whether each gemstone ID when a valid one is found (for each type)
        uint16 gemOneValid = 0;
        uint16 gemTwoValid = 0;
        uint16 gemThreeValid = 0;
        uint16 gemFourValid = 0;
        uint16 gemFiveValid = 0;
        uint16 gemSixValid = 0;

        // get validity status of each gemstone that the caller owns (from callerOwnedGems[])
        for (uint256 i = 0; i < NFTsCount; i++) {
            uint16 gemId = callerOwnedGems[i];

            // make sure the current gemstone is valid (i.e. not redeemed)
            if (isGemRedeemedForId(gemId)) {
                // gem has been redeemed, so skip to the next gem 
                continue;
            } else if (gemId <= 50) {
                // gem is gemstone 1 (1-50)
                gemOneValid = gemId;
            } else if (gemId <= 100) {
                // gem is gemstone 2 (51-100)
                gemTwoValid = gemId;
            } else if (gemId <= 150) {
                // gem is gemstone 3 (101-150)
                gemThreeValid = gemId;
            } else if (gemId <= 200) {
                // gem is gemstone 4 (151-200)
                gemFourValid = gemId;
            } else if (gemId <= 250) {
                // gem is gemstone 5 (201-250)
                gemFiveValid = gemId;
            } else if (gemId <= 300) {
                // gem is gemstone 6 (251-300)
                gemSixValid = gemId;
            }
            
        }

        if ((gemOneValid > 0) && (gemTwoValid > 0) && (gemThreeValid > 0) && (gemFourValid > 0) && (gemFiveValid > 0) && (gemSixValid > 0)) {
            return [gemOneValid, gemTwoValid, gemThreeValid, gemFourValid, gemFiveValid, gemSixValid];
        } else {
            uint16[6] memory emptyArray;
            return emptyArray; // not enough valid gemstones of all types. return all 0s
        }
    }


    /*
        Public function to be called to redeem gemstones when minting goblet.
        It returns true after setting all the gemstones as redeemed. 
        AUTOMATICALLY CHECKS WHETHER CALLER IS ELIGIBLE TO REDEEM OR NOT. 
        False if user fails condition to mint goblet. 
        This function must check if caller is eligible to mint the goblet. Otherwise it will create a security issue. 
        @param gemstoneIDs array of gemstones to redeem
        @returns bool true if all gemstones are successfully redeemed, false if not
    */
    function redeemGemstonesForGoblet(address customerAddress)
        public
        returns (bool)
    {
        // check if the caller is eligible to redeem his gemstones (to avoid illegal redemptions)
        uint16[6] memory callerOwnedValidGems = isEligibleToMintGoblet(customerAddress);
        // if the first index is 0, then they are not eligible to redeem
        if (callerOwnedValidGems[0] == 0) {
            // console.log("Return false because first index is 0!");
            return false;
        }
        // the customer has 6 valid gemstones, so now redeem them. 
        return redeemGemstonesByID(callerOwnedValidGems);
    }

    //View fns

    function getOwner() public view returns (address) {
        return getOwnerAddress();
    }

    //Returns purchases for a customer
    //Adding for future use by contract #2
    function getPurchasesOfCustomer(address customerAddress)
        public
        view
        returns (Types.PurchaseInfo[] memory purchases)
    {
        return getPurchasesOfUser(customerAddress);
    }

    //Returns purchases for the contract
    //Adding for future use by contract #2
    function getAllPurchases()
        public
        view
        returns (Types.PurchaseInfo[] memory purchaseInfos)
    {
        return getPurchases();
    }

    /* 
        Function to update the CID of the gemstones metadata. 
        Can update redeemed or unredeemed gemstones metadata depeding on `updateRedeemed` parameter.
        @param _cid is the new CID of the metadata.
        @param updateRedeemed is a bool that determines whether to update the redeemed or unredeemed metadata.
    */
    function updateCID(string calldata _cid, bool updateRedeemed) public onlyOwner { 
        if (updateRedeemed) { 
            redeemedMetadataCID = _cid;
        } else {  
            unredeemedMetadataCID = _cid;
        }
    }

    /*
        Returns uri for marketplaces
        We maintain 2 stores for metadata
        #1 For redeemed (Will be returned for items which are not redeemed)
        #2 For unredeemed (Default state)
        @param customerAddress address of customer
        @param gemstoneType gemstone type
        Range of gemstone type is defined in Types.sol (0..5)
    */
    function uri(uint256 id) public view override returns (string memory) {
        if (!isGemRedeemedForId(uint256(id))) {
            return
                string(
                    abi.encodePacked(
                        "ipfs://",
                        unredeemedMetadataCID,
                        "/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Not redeemed ipfs
        } else {
            return
                string(
                    abi.encodePacked(
                        "ipfs://",
                        redeemedMetadataCID,
                        "/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Redeemed ipfs
        }
    }
}
