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
    address immutable owner;

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
        Similar to purchases mapping, except traversed by gemstone ID for easier querying.
        Retrofitted onto the V1 of the contract, hence not totally replacing `purchases` mapping, or `redeemedList` mapping.
        Key is gemstone ID. Maps to purchase info.
    */
    mapping (uint256 => Types.PurchaseInfo[]) purchasesByGemstone;

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
        // Make sure new purchase is not violating supply limit
        require(
            gemstones[gemType].lastMintedId < gemstones[gemType].supply - 1, 
        "No more gemstones available");

        uint256 lastMinted = gemstones[gemType].lastMintedId;
        Types.PurchaseInfo memory newPurchase = Types.PurchaseInfo(
            Types.GemstoneType(gemType),
            lastMinted + 1,
            block.timestamp,
            block.timestamp + VALIDITY_PERIOD,
            false
        );
        uint256 gemstoneId = gemstoneType * 50 + lastMinted + 1; // this ID is 1-300 for all gemstones
        // update all mappings tracking purchased gemstones 
        purchases[customerAddress].push(newPurchase);
        purchasesByGemstone[gemstoneId].push(newPurchase);
        gemstones[gemType].lastMintedId += 1;
        addToCustomerLookupTable(customerAddress);

        // (replacing the deprecated `addToRedeemedWithDefault`): 
        redeemedList[gemstoneId] = 0; // (set by default to false)

        return lastMinted + 1;
    }

    /*
        Add address to whitelist for a gemstone type
        @param customerAddress address of customer
        @param gemstoneType gemstone type
    */
    function addToWhitelist(address customerAddress, uint256 gemType) internal {
        require(
            (gemType >= 0 && gemType <= 5),
            "Gemstone does not exist"
        );
        address[] storage whitelist = bundleWhitelist[Types.GemstoneType(gemType)];
        if(whitelist.length == 0) {
            bundleWhitelist[Types.GemstoneType(gemType)].push(customerAddress);
        }
        else {
            for (uint256 i = 0; i < whitelist.length; i++) {
                require(whitelist[i] != customerAddress, "Address already in whitelist"); 
            }
            bundleWhitelist[Types.GemstoneType(gemType)].push(customerAddress);
        }
    }

    // THIS FUNCTION IS USELESS, AND NOT USED. DELETE LATER. 
    // /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
    /*
        function addToRedeemedWithDefault(uint256 gemType) internal {
            redeemedList[gemType] = 0;
        }
    */
    // /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

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
        require(gemstoneType >= 0 && gemstoneType <= 5, "Invalid gemstone type");
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

    //Returns if a gemstone type was minted for a customer (to avoid customers double-minting the same gemstone type)
    //@param customerAddress address of customer
    //@param gemId gemstone type
    function isGemstoneMinted(address customerAddress, uint256 gemType)
        public
        view
        returns (bool)
    {
        require(gemType >= 0 && gemType <= 5);
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

    
    // THIS FUNCTION IS BROKEN, AND OUT OF USE. NEW ELIGIBILITY CHECKING FUNCTION IS BELOW.
    // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    /*
        Returns if the user has 6 gemstones redeemable
        Redeemable is true in 2 conditions
        1. The gemstone is not redeemed
        2. The gemstone is redeemed but past the validity period
        @param customerAddress customer address
    function isEligibleToMintGoblet(address customerAddress)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < purchases[customerAddress].length; i++) {
            Types.PurchaseInfo memory purchase = purchases[customerAddress][i];
            if (purchase.redeemed == false || block.timestamp > purchase.validityDate)
            {
                validGemCount += 1;
            }
        }
        return validGemCount == 6;
    }
    */
    // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    
    /* 
        NEW ELIGIBILITY CHECKING FUNCTION
        Returns if the user has 6 gemstones redeemable
        Redeemable is true in 2 conditions
        1. The gemstone is not redeemed
        2. The gemstone is redeemed but past the validity period
        @param callerAdrress caller address (passed as parameter, not msg.sender, because function may be called by goblet.sol contract)
    */
    function isEligibleToMintGoblet(address callerAddress) public view returns (bool isEligibleToMintGoblet) {

        // if its the owner, they can always mint, so return true immediately. 
        if (callerAddress == owner) {
            return true;
        }

        // firstly, find which gemstones the caller owns by running BalanceOf() through all NFT IDs (1-300) 
        // unfortunately while inefficient, this is the only option that makes sense in this scenario. 
        mapping(uint256 => uint256) callerOwnedGems; 
        uint NFTsCount = 0;
        for (uint i = 1; i < 301; i++) {
            if ((balanceOf(callerAddress, i)) > 0) {
                // if token balance > 0, the caller has the NFT with ID `i` 
                callerOwnedGems[NFTsCount] = i; // store the ID of the NFT 
                NFTsCount ++;
            }
        }

        // check they have at least 6 gemstones (otherwise stop further logic)
        require(NFTsCount > 5, "You don't have enough gemstones to redeem for a goblet");

        // if they have 6, check they're at least one of each type 

        // booleans to store whether each gemstone is valid or not 
        bool gemOneValid = false;
        bool gemTwoValid = false;
        bool gemThreeValid = false;
        bool gemFourValid = false;
        bool gemFiveValid = false;
        bool gemSixValid = false;

        // get validity status of each gemstone that the caller owns (from callerOwnedGems[])
        for (uint256 i = 0; i < callerOwnedGems.length; i++) {
            gemId = callerOwnedGems[i];

            // make sure the current gemstone is valid (i.e. not redeemed)
            if (isGemRedeemedForId(gemId)) {
                // gem has been redeemed, so skip to the next gem 
                continue;
            } else if (gemId <= 50) {
                // gem is gemstone 1 (1-50)
                gemOneValid = true;
            } else if (gemId <= 100) {
                // gem is gemstone 2 (51-100)
                gemTwoValid = true;
            } else if (gemId <= 150) {
                // gem is gemstone 3 (101-150)
                gemThreeValid = true;
            } else if (gemId <= 200) {
                // gem is gemstone 4 (151-200)
                gemFourValid = true;
            } else if (gemId <= 250) {
                // gem is gemstone 5 (201-250)
                gemFiveValid = true;
            } else if (gemId <= 300) {
                // gem is gemstone 6 (251-300)
                gemSixValid = true;
            }
            
        }

        if (gemOneValid && gemTwoValid && gemThreeValid && gemFourValid && gemFiveValid && gemSixValid) {
            return true;
        } else {
            return false; // not enough valid gemstones of all types 
        }
    }

    /* 
        Returns if the gemstone is redeemed for the ID. 
        This is used to serve different URIs (for redeemed gemstones)
        And also used to check eligibility for goblet minting. This function is crucial. 
        @param gemstoneId gemstone ID
        @returns bool isRedeemed
    */
    function isGemRedeemedForId(uint256 gemId) internal view returns (bool) {
        // NOTE: Is this function working ? It seems that the gemstones will only be redeemable a year after they've been redeemed the first time. 
        // (instead of being redeemable depending what year it is)
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

    // Note from Joao: not deleting this (because I didn't write it), but why does it exist? I realise it's a public function in GemstoneMinter.sol, but why would it ever be used? 
    function getOwnerAddress() internal view returns (address) {
        return owner;
    }

    // Functions exposed for goblet contract

    /*
        Redeems (up to) 6 gemstones at once (for the goblet contract)
        This function is accessible to the public (through GemstoneMinter.sol) and therefore eligibility to mint a goblet must be checked (otherwise non-eligible parties could redeem gemstones)
        Updates the purchase status as redeemed for each gemstone in the input array 
        @param gemstoneIDs array of gemstone IDs 
        @param callerAddress address of the caller (passed as parameter not msg.sender, so that it can be called from goblet.sol)
        @returns bool true if all gemstones are successfully redeemed, false if not
    */
    function redeemGemstonesByID(uint256[6] memory gemstoneIDs, address callerAddress)
        internal
        returns (bool)
    {
        // check if the caller is eligible to redeem his gemstones (to avoid illegal redemptions)
        if (!isEligibleToMintGoblet(callerAddress)) {
            return false;
        }
        // will redeem (up to) 6 gemstones at once (for the goblet contract) 
        
        // loop through each of the 6 gemstone IDs passed into the function 
        for (uint256 i = 0; i < gemstoneIDs.length; i++) {
            // make sure the gemstone of ID `i` actually exists: 
            if (!(purchasesByGemstone[gemstoneIDs[i]].length == 0)) {
                // since it exists, retrieve the information & update the properties 
                Types.PurchaseInfo memory purchase = purchasesByGemstone[gemstoneIDs[i]];
                if (purchase.redeemed == false) {
                    purchase.redeemed = true; 
                    purchase.redeemedDate = block.timestamp;
                    purchasesByGemstone[[gemstoneIDs][i]] = purchase;
                    redeemedList[gemstoneIDs[i]] = block.timestamp;
                }
            }
        }
        return true;

        // OLD CODE. NOT USED.
        // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
        /* 
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
        */
        // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    }

    // OLD CODE. NOT USED. DEPRECATED FUNCTINO USED TO REDEEM GEMSTONES 
    // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    /*
        function redeemGemstone(address customerAddress, uint256 gemId) internal {
            for (uint256 i = 0; i < purchases[customerAddress].length; i++) {
                if (purchases[customerAddress][i].gemId == gemId) {
                    purchases[customerAddress][i].redeemed = true;
                    break;
                }
            }
            redeemedList[gemId] = block.timestamp;
        }
    */
    // \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
}
