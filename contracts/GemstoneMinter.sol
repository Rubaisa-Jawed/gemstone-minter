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

    function mint(address customerAddress, uint8 gemstoneType) public payable {
        require(isGemstoneAvailable(gemstoneType), "Gemstone not available");
        require(
            !isGemstoneMinted(customerAddress, gemstoneType),
            "Gemstone already minted"
        );
        addToWhitelist(customerAddress, gemstoneType);
        uint8 gemId = recordPurchase(customerAddress, gemstoneType);
        uint8 mintId = gemstoneType * 100 + gemId;
        addToRedeemedWithDefault(mintId);
        _mint(customerAddress, mintId, 1, "");
        console.log("Minted: ", Strings.toString(mintId));
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
    function redeemGemstoneExperimental(address customerAddress, uint8 gemId)
        public
    {
        redeemGemstone(customerAddress, gemId);
    }
}
