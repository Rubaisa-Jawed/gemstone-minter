//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Gemstone.sol";
import {Types} from "./libs/Types.sol";

contract GemstoneMinter is Gemstone, ERC1155 {
    constructor() ERC1155("www.example.com") {
        console.log("Init GemstoneMinter success");
    }

    function mint(address customerAddress, uint8 gemstoneType) public payable {
        require(isGemstoneAvailable(gemstoneType), "Gemstone not available");
        require(
            !isGemstoneMinted(customerAddress, gemstoneType),
            "Gemstone already minted"
        );
        addToWhitelist(customerAddress, gemstoneType);
        recordPurchase(customerAddress, gemstoneType);
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
}
