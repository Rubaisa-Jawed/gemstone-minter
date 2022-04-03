//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import {Types} from "./libs/Types.sol";

contract Gemstone {
    /*
        Validity of gemstone until it can be redeemed once again
    */
    uint256 constant VALIDITY_PERIOD = 31556952; //1 year

    //Owner address
    address owner;

    /*
        Lookup table for customer addresses and that purchased gemstones and minted
    */
    address[] customerAddresses;

    /*
        A mapping that maintains last minted gemstone id for each gemstone type
        It also defines total supply for each
    */
    Types.Gemstone[] gemstones;

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
        The source of truth for redeemed gemstone id for easier querying
        Key is gemstone id, value is true if the gemstone is redeemed
        Not redeemed state = 0
        Redeemed state = VALID TIMESTAMP
    */
    mapping(uint256 => uint256) redeemedList;

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
        Adds to purchases
        Update last minted in gemstones
        @param customerAddress address of customer
        @param gemstoneType gemstone type

        Range of gemstone type is defined in Types.sol (0..5)

        Returns the gemId of the gemstone that is last minted
    */
    function recordPurchase(address customerAddress, uint256 gemType)
        internal
        returns (uint256 gemId)
    {
        require(gemType >= 0 && gemType <= uint256(Types.GemstoneType.Ruby));
        require(
            gemstones[gemType].lastMintedId < gemstones[gemType].supply - 1
        );
        uint256 lastMinted = gemstones[gemType].lastMintedId;
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

    /*
        Add address to whitelist for a gemstone type
        @param customerAddress address of customer
        @param gemstoneType gemstone type
    */
    function addToWhitelist(address customerAddress, uint256 gemType) internal {
        require(
            (gemType >= 0 && gemType <= uint256(Types.GemstoneType.Ruby)),
            "Gemstone does not exist"
        );
        address[] storage whitelist = bundleWhitelist[
            Types.GemstoneType(gemType)
        ];
        for (uint256 i = 0; i <= whitelist.length; i++) {
            require(
                whitelist[i] != customerAddress,
                "Address already in whitelist"
            );
            bundleWhitelist[Types.GemstoneType(gemType)].push(customerAddress); 
        }
    }

    function addToRedeemedWithDefault(uint256 gemType) internal {
        redeemedList[gemType] = 0;
    }

    /*
        Add customer address to lookup table
        Adds only unique customer addresses
        @param customerAddress address of customer
    */
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

    /*
        Check if customer has been whitelisted
    */
    function isCustomerWhiteListed(address customerAddress, uint256 gemstoneType)
        internal
        view
        returns (bool)
    {
        require(
            gemstoneType >= 0 && gemstoneType <= uint256(Types.GemstoneType.Ruby)
        );
        address[] storage whitelist = bundleWhitelist[
            Types.GemstoneType(gemstoneType)
        ];
        bool isWL = false;
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == customerAddress) {
                isWL = true;
            }
        }
        return isWL;
    }

    //Returns if the gemstone last minted is less than supply
    //@param gemstoneType gemstone type
    function isGemstoneAvailable(uint256 gemType) public view returns (bool) {
        return gemstones[gemType].lastMintedId < gemstones[gemType].supply - 1;
    }

    //Returns if the gemstone was minted for the customer
    //@param customerAddress address of customer
    //@param gemId gemstone type
    function isGemstoneMinted(address customerAddress, uint256 gemType)
        public
        view
        returns (bool)
    {
        require(gemType >= 0 && gemType <= uint256(Types.GemstoneType.Ruby));
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

    /*
        Returns if the user has 6 gemstones redeemable
        Redeemable is true in 2 conditions
        1. The gemstone is not redeemed
        2. The gemstone is redeemed but past the validity period
        @param customerAddress customer address
    */
    function isEligibleToMintGoblet(address customerAddress)
        public
        view
        returns (bool)
    {
        uint256 validGemCount = 0;
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

    //Returns if the gemstone is redeemed for the ID. This is used to serve different URI
    function isGemRedeemedForId(uint256 gemId) internal view returns (bool) {
        console.log(redeemedList[gemId]);
        if (redeemedList[gemId] == 0) return false;
        else if (block.timestamp > redeemedList[gemId] + VALIDITY_PERIOD)
            return false;
        else return true;
    }

    //Returns purchases of customer
    function getPurchasesOfUser(address customerAddress)
        internal
        view
        returns (Types.PurchaseInfo[] memory)
    {
        return purchases[customerAddress];
    }

    //Returns all customer addresses
    function getAddressesOfAllCustomers()
        internal
        view
        returns (address[] memory)
    {
        return customerAddresses;
    }

    //Get total number of purchases
    function getTotalNumberOfPurchases() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < customerAddresses.length; i++) {
            total += purchases[customerAddresses[i]].length;
        }
        return total;
    }

    //Get all purchases
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

    /*
        Checks if customer is eligible to Mint a goblet
        Updates the purchase status as redeemed for each gemstone if true
        @param customerAddress address of customer
    */
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

    function redeemGemstone(address customerAddress, uint256 gemId) internal {
        for (uint256 i = 0; i < purchases[customerAddress].length; i++) {
            if (purchases[customerAddress][i].gemId == gemId) {
                purchases[customerAddress][i].redeemed = true;
                break;
            }
        }
        redeemedList[gemId] = block.timestamp;
    }
}
