//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import {Types} from "./libs/Types.sol";

contract Gemstone {
    //Owner address
    address owner;

    /*
        Maintain address whitelist for each gemstone type
        Gemstone types are defined in Types.sol
    */
    mapping(Types.GemstoneType => address[]) bundleWhitelist;

    /*
        Maintain purchase history for each address
        PurchaseInfo type is defined in Types.sol
        Purchase info has redeemed field to indicate if the gemstone is redeemed,
        the source of truth is duplicated in the redeemedList for easier querying
    */
    mapping(address => Types.PurchaseInfo[]) purchases;

    /*
        Lookup table for customer addresses and that purchased gemstones
    */
    address[] customerAddresses;

    /*
        A mapping that maintains last minted gemstone id for each gemstone type
        It also defines total supply for each
    */
    Types.Gemstone[] gemstones;

    /*
        The source of truth for redeemed gemstone id for easier querying
        Key is gemstone id, value is true if the gemstone is redeemed
        Not redeemed state = 0
        Redeemed state = VALID TIMESTAMP
    */
    mapping(uint8 => uint256) redeemedList;

    /*
        Validity of gemstone until it can be redeemed once again
    */
    uint256 constant VALIDITY_PERIOD = 31556952; //1 year

    //Initialise supplies, store owner address to access laters
    constructor() {
        owner = msg.sender;
        initBundleWhitelist();
        initGemstones();
        console.log("Init Gemstone success at", block.timestamp);
    }

    //Writes

    /*
        Add address to whitelist for a gemstone type
        @param customerAddress address of customer
        @param gemstoneType gemstone type

        Range of gemstone type is defined in Types.sol (0..5)

        Returns the gemId of the gemstone that is last minted
    */
    function recordPurchase(address customerAddress, uint8 gemType)
        internal
        returns (uint8 gemId)
    {
        require(gemType >= 0 && gemType <= uint8(Types.GemstoneType.Ruby));
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
        addToCustomerLookupTable(customerAddress);
        return lastMinted + 1;
    }

    function addToWhitelist(address customerAddress, uint8 gemType) internal {
        require(gemType >= 0 && gemType <= uint8(Types.GemstoneType.Ruby));
        bundleWhitelist[Types.GemstoneType(gemType)].push(customerAddress);
    }

    function addToRedeemedWithDefault(uint8 gemType) internal {
        redeemedList[gemType] = 0;
    }

    function addToCustomerLookupTable(address customerAddress) internal {
        //Dont push if already exists
        for (uint64 i = 0; i < customerAddresses.length; i++) {
            if (customerAddresses[i] == customerAddress) {
                return;
            }
        }
        customerAddresses.push(customerAddress);
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
        require(gemType >= 0 && gemType <= uint8(Types.GemstoneType.Ruby));
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
        if (gemId > 0 && gemId <= uint8(Types.GemstoneType.Amethyst) * 100 + 50)
            return uint8(Types.GemstoneType.Amethyst);
        else if (
            gemId > uint8(Types.GemstoneType.Amethyst) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Sapphire) * 100 + 50
        ) return uint8(Types.GemstoneType.Sapphire);
        else if (
            gemId > uint8(Types.GemstoneType.Sapphire) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Emerald) * 100 + 50
        ) return uint8(Types.GemstoneType.Emerald);
        else if (
            gemId > uint8(Types.GemstoneType.Emerald) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Citrine) * 100 + 50
        ) return uint8(Types.GemstoneType.Citrine);
        else if (
            gemId > uint8(Types.GemstoneType.Citrine) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Amber) * 100 + 50
        ) return uint8(Types.GemstoneType.Amber);
        else if (
            gemId > uint8(Types.GemstoneType.Amber) * 100 + 100 &&
            gemId <= uint8(Types.GemstoneType.Ruby) * 100 + 50
        ) return uint8(Types.GemstoneType.Ruby);
        else return uint8(Types.GemstoneType.Amethyst);
    }

    function getPurchasesOfUser(address customerAddress)
        internal
        view
        returns (Types.PurchaseInfo[] memory)
    {
        return purchases[customerAddress];
    }

    function getAddressesOfAllCustomers()
        internal
        view
        returns (address[] memory)
    {
        return customerAddresses;
    }

    function getTotalNumberOfPurchases() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < customerAddresses.length; i++) {
            total += purchases[customerAddresses[i]].length;
        }
        return total;
    }

    function getPurchases()
        internal
        view
        returns (Types.PurchaseInfo[] memory)
    {
        uint256 purchasesLength = getTotalNumberOfPurchases();
        Types.PurchaseInfo[] memory purchaseInfos = new Types.PurchaseInfo[](
            purchasesLength
        );
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < customerAddresses.length; i++) {
            for (
                uint256 j = 0;
                j < purchases[customerAddresses[i]].length;
                j++
            ) {
                purchaseInfos[currentIndex] = purchases[customerAddresses[i]][
                    j
                ];
            }
        }
        return purchaseInfos;
    }

    //TODO - add a function to get whitelist of a particular gemstone type
    //TODO - add a function to get all purchases
    //TODO - add a function to get supply left for a specific gemstone type

    //Inititalisers
    function initBundleWhitelist() internal {
        bundleWhitelist[Types.GemstoneType.Amethyst] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Sapphire] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Emerald] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Citrine] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Amber] = new address[](0);
        bundleWhitelist[Types.GemstoneType.Ruby] = new address[](0);
    }

    function initGemstones() internal {
        gemstones.push(Types.Gemstone(Types.GemstoneType.Amethyst, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Sapphire, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Emerald, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Citrine, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Amber, 50, 0));
        gemstones.push(Types.Gemstone(Types.GemstoneType.Ruby, 50, 0));
    }

    function getOwnerAddress() internal view returns (address) {
        return owner;
    }

    //Functions exposed for goblet contract
    function redeemPurchasesForGoblet(address customerAddress)
        internal
        returns (bool)
    {
        if (isEligibleToMintGoblet(customerAddress)) {
            for (uint256 i = 0; i < purchases[customerAddress].length; i++) {
                if (purchases[customerAddress][i].redeemed == false) {
                    purchases[customerAddress][i].redeemed = true;
                    redeemedList[
                        purchases[customerAddress][i].gemId + 100
                    ] = block.timestamp;
                }
            }
            return true;
        } else {
            return false;
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
