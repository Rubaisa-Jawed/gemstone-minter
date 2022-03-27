//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import {Types} from "./libs/Types.sol";

contract Gemstone {
    //State vars:
    address owner;
    mapping(Types.GemstoneType => address[]) bundleWhitelist; //For reference
    mapping(address => Types.PurchaseInfo[]) purchases;
    Types.Gemstone[] gemstones;
    mapping(uint8 => uint256) redeemedList;
    uint256 constant VALIDITY_PERIOD = 31556952; //1 year

    constructor() {
        owner = msg.sender;
        initBundleWhitelist();
        initGemstones();
        console.log("Init Gemstone success at", block.timestamp);
    }

    //Writes
    function recordPurchase(address customerAddress, uint8 gemType)
        internal
        returns (uint8 gemId)
    {
        require(gemType >= 0 && gemType <= uint8(Types.GemstoneType.Goblet));
        require(
            gemstones[gemType].lastMintedId < gemstones[gemType].supply - 1
        );
        uint8 lastMinted = gemstones[gemType].lastMintedId;
        Types.PurchaseInfo memory newPurchase = Types.PurchaseInfo(
            Types.GemstoneType(gemType),
            lastMinted + 1,
            block.timestamp,
            block.timestamp + VALIDITY_PERIOD,
            false
        );
        purchases[customerAddress].push(newPurchase);
        gemstones[gemType].lastMintedId += 1;
        return lastMinted + 1;
    }

    function addToWhitelist(address customerAddress, uint8 gemType) internal {
        require(gemType >= 0 && gemType <= uint8(Types.GemstoneType.Goblet));
        bundleWhitelist[Types.GemstoneType(gemType)].push(customerAddress);
    }

    function addToRedeemedWithDefault(uint8 gemType) internal {
        redeemedList[gemType] = 0;
    }

    //Reads
    function isGemstoneAvailable(uint8 gemType) public view returns (bool) {
        return gemstones[gemType].lastMintedId < gemstones[gemType].supply - 1;
    }

    function isGemstoneMinted(address customerAddress, uint8 gemType)
        public
        view
        returns (bool)
    {
        require(gemType >= 0 && gemType <= uint8(Types.GemstoneType.Goblet));
        bool isMinted = false;
        for (uint256 i = 0; i < purchases[customerAddress].length; i++) {
            Types.PurchaseInfo memory purchase = purchases[customerAddress][i];
            if (purchase.gemstoneType == Types.GemstoneType(gemType)) {
                isMinted = true;
                break;
            }
        }
        return isMinted;
    }

    function isEligibleToMintGoblet(address customerAddress)
        public
        view
        returns (bool)
    {
        uint8 validGemCount = 0;
        for (uint256 i = 0; i < purchases[customerAddress].length; i++) {
            Types.PurchaseInfo memory purchase = purchases[customerAddress][i];
            if (
                purchase.redeemed == false ||
                (purchase.redeemed && block.timestamp > purchase.validityDate)
            ) {
                validGemCount += 1;
            }
        }
        return validGemCount == 6;
    }

    function isGemRedeemedForId(uint8 gemId) internal view returns (bool) {
        if (redeemedList[gemId] == 0) return false;
        else if (block.timestamp > redeemedList[gemId] + VALIDITY_PERIOD)
            return false;
        else return true;
    }

    function getGemstoneType(uint8 gemId) internal pure returns (uint8) {
        if (gemId > 0 && gemId <= uint8(Types.GemstoneType.Azure) * 100 + 50)
            return uint8(Types.GemstoneType.Azure);
        else if (
            gemId > uint8(Types.GemstoneType.Azure) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Lapis) * 100 + 50
        ) return uint8(Types.GemstoneType.Lapis);
        else if (
            gemId > uint8(Types.GemstoneType.Lapis) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Saphirre) * 100 + 50
        ) return uint8(Types.GemstoneType.Saphirre);
        else if (
            gemId > uint8(Types.GemstoneType.Saphirre) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Emerald) * 100 + 50
        ) return uint8(Types.GemstoneType.Emerald);
        else if (
            gemId > uint8(Types.GemstoneType.Emerald) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Ruby) * 100 + 50
        ) return uint8(Types.GemstoneType.Ruby);
        else if (
            gemId > uint8(Types.GemstoneType.Ruby) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Diamond) * 100 + 50
        ) return uint8(Types.GemstoneType.Diamond);
        else return uint8(Types.GemstoneType.Azure);
    }

    function getPurchasesOfUser(address customerAddress)
        internal
        view
        returns (Types.PurchaseInfo[] memory)
    {
        return purchases[customerAddress];
    }

    //TODO - add a function to get whitelist of a particular gemstone type
    //TODO - add a function to get all purchases
    //TODO - add a function to get supply left for a specific gemstone type

    //Inititalisers
    function initBundleWhitelist() internal {
        bundleWhitelist[Types.GemstoneType.Azure] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Lapis] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Saphirre] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Emerald] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Ruby] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Diamond] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Goblet] = new address[](0);
    }

    function initGemstones() internal {
        gemstones.push(Types.Gemstone(Types.GemstoneType.Azure, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Lapis, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Saphirre, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Emerald, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Ruby, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Diamond, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Goblet, 50, 0));
    }

    function getOwnerAddress() internal view returns (address) {
        return owner;
    }

    //Goblet fns
    function addGobletIfEligible(address customerAddress) internal {
        if (isEligibleToMintGoblet(customerAddress)) {
            Types.PurchaseInfo memory newPurchase = Types.PurchaseInfo(
                Types.GemstoneType.Goblet,
                0,
                block.timestamp,
                block.timestamp + VALIDITY_PERIOD,
                false
            );
            purchases[customerAddress].push(newPurchase);
        }
    }

    function redeemGemstone(address customerAddress, uint8 gemId) internal {
        for (uint8 i = 0; i < purchases[customerAddress].length; i++) {
            if (purchases[customerAddress][i].gemId == gemId) {
                purchases[customerAddress][i].redeemed = true;
                break;
            }
        }
        redeemedList[gemId] = block.timestamp;
    }
}
