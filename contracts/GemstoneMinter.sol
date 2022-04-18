//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Gemstone.sol";
import {Types} from "./libs/Types.sol";

contract GemstoneMinter is Gemstone, ERC1155 {
    //This is for opensea contract name display
    string public name = "MultiGrain & Cane Whiskey";

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

        //check if gemstone type has been minted by a specific customeraddress
        require(
            !isGemstoneMinted(customerAddress, gemstoneType),
            "Gemstone already minted"
        );

        //mint of gemstone is recorded in mapping
        uint256 gemId = recordPurchase(customerAddress, gemstoneType);
        uint256 mintId = gemstoneType * 50 + gemId;

        //Set redeemed as false by default
        addToRedeemedWithDefault(mintId);

        //Mint
        _mint(customerAddress, mintId, 1, "");
        console.log("Whitelisted minted: ", Strings.toString(mintId));
    }

    /*
        Public function to be called by contract owner to mint a goblet
        It returns true after setting all the gemstones as redeemed
        False if user fails condition to mint goblet
    */
    function redeemGemstonesForGoblet(address customerAddress)
        public
        returns (bool)
    {
        return redeemPurchasesForGoblet(customerAddress);
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
                        "ipfs://QmPRTF5r8FV7bTQmCf7x7ofKKBApaYFwN53A5uDVpDXv3K/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Not redeemed ipfs
        } else {
            return
                string(
                    abi.encodePacked(
                        "ipfs://Qme3hQAv8sZHVtJ7GNMfLBv3siTRQcTT7FJxfAcCMJ4A7T/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Redeemed ipfs
        }
    }

    //TODO Remove after testing
    //Not required here
    function redeemGemstoneExperimental(address customerAddress, uint256 gemId)
        public
        onlyOwner
    {
        redeemGemstone(customerAddress, gemId);
    }
}
