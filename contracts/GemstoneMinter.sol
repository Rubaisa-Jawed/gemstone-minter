//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Gemstone.sol";
import {Types} from "./libs/Types.sol";

contract GemstoneMinter is Gemstone, ERC1155 {
    constructor()
        ERC1155(
            "ipfs://QmcjzQsiFaCLmvvgsjLwqRc7nEc5nUjavVD5u7WAn31MkZ/{id}.json"
        )
    {
        console.log("Init GemstoneMinter success");
    }

    //main function for public minting
    function mint(address customerAddress, uint8 gemstoneType) public payable {
        require(isGemstoneAvailable(gemstoneType), "Gemstone not available"); //check if gemstone is available for minting
        require(
            !isGemstoneMinted(customerAddress, gemstoneType),
            "Gemstone already minted"
        ); //check if gemstone type has been minted by a specific customeraddress
        uint8 gemId = recordPurchase(customerAddress, gemstoneType); //mint of gemstone is recorded in mapping
        uint8 mintId = gemstoneType * 50 + gemId;
        addToRedeemedWithDefault(mintId);
        _mint(customerAddress, mintId, 1, "");
        console.log("Minted: ", Strings.toString(mintId));
    }

    //function for adding address to whitelist for specific gemstone types
    function addAddressToWhitelist(address customerAddress, uint8 gemstoneType)
        public
        onlyOwner
    {
        require(gemstoneType >= 0 && gemstoneType <= uint8(Types.GemstoneType.Diamond), "Gemstone does not exist");
        addToWhitelist(customerAddress, gemstoneType);
    }

    //function for whitelist minting
    function whitelistMint(address customerAddress, uint8 gemstoneType) public payable {
        address[] storage whitelist = bundleWhitelist[Types.GemstoneType(gemstoneType)];
        bool isWL = false;
        for (uint8 i = 0; i < whitelist.length; i++) {
            if(whitelist[i] == customerAddress) {
                isWL = true;
            }
        }
        require(isWL == true, "Address does not have whitelist for this gemstone type");  //check if whitelist exists for this gemstone type
        require(isGemstoneAvailable(gemstoneType), "Gemstone not available"); //check if gemstone is available for minting
        require(
            !isGemstoneMinted(customerAddress, gemstoneType),
            "Gemstone not minted");  //check if gemstone type has been minted by a specific customeraddress
        uint8 gemId = recordPurchase(customerAddress, gemstoneType);  //mint of gemstone is recorded in mapping
        uint8 mintId = gemstoneType * 50 + gemId;
        addToRedeemedWithDefault(mintId);
        _mint(customerAddress, mintId, 1, "");
        console.log("Whitelisted minted: ", Strings.toString(mintId));
    }

    function getOwner() public view returns (address) {
        return getOwnerAddress();
    }

    function getPurchasesOfCustomer(address customerAddress)
        public
        view
        returns (Types.PurchaseInfo[] memory purchases)
    {
        return getPurchasesOfUser(customerAddress);
    }

    function uri(uint256 id) public view override returns (string memory) {
        if (isGemRedeemedForId(uint8(id))) {
            return
                "ipfs://QmWo3zWi7a2PjEg43KaPCnaRqp3F9JxHTMFc7ejhKXsReF/{id}.json"; //Not redeemed ipfs
        } else {
            return
                "ipfs://QmNW6jFna4EFfsvRBuoYy3PatnaEwVLB19P2D7Tyj5H6CH/{id}.json"; //Redeemed ipfs
        }
    }

    //TODO Remove after testing
    //Not required here
    function redeemGemstoneExperimental(address customerAddress, uint8 gemId)
        public
    {
        redeemGemstone(customerAddress, gemId);
    }
}
