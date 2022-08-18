//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Gemstone.sol";
import {Types} from "./libs/Types.sol";

contract GemstoneMinter is Gemstone, ERC1155 {
    //This is for opensea contract name display
    string public name = "Malt Grain & Cane Whiskey";

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
            !isGemstoneMinted(mintId),
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
        console.log("Whitelisted minted: ", Strings.toString(mintId));
    }

    /*
        Public function to be called to redeem gemstones when minting goblet.
        It returns true after setting all the gemstones as redeemed.
        False if user fails condition to mint goblet. 
        This function must check if caller is eligible to mint the goblet. Otherwise it will create a security issue. 
        @param gemstoneIDs array of gemstones to redeem
        @returns bool true if all gemstones are successfully redeemed, false if not
    */
    function redeemGemstonesForGoblet(uint256[6] memory gemstoneIDs)
        public
        returns (bool)
    {
        return redeemGemstonesByID(customerAddress);
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
                        "ipfs://QmYn21JY4tgB7EN35z11papkWG2YqyNdqiZJDN78zh8hYc/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Not redeemed ipfs
        } else {
            return
                string(
                    abi.encodePacked(
                        "ipfs://QmaUzAyJ5hrovGtPdVg9ZQTjo1Q2ZYU7ztZ1SQG3C6Z26D/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Redeemed ipfs
        }
    }

    // THIS CODE DOES NOT WORK. DELETE LATER. 
    // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    /*
        function redeemGemstoneExperimental(address customerAddress, uint256 gemId)
            public
            onlyOwner
        {
            redeemGemstone(customerAddress, gemId);
        }
    */ 
    // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
}
