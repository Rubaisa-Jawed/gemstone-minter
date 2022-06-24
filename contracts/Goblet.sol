//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Goblet {
    struct GobletOwnership {
        address owner;
        uint256 gobletId;
        uint256 mintedDate; // Set with block.timestamp
    }

    uint256 private constant VALIDITY_PERIOD = 31556952; //3 Years

    uint256 private immutable INITIAL_DATE; //Date of contract deployment (2022)

    uint256 private constant SECONDS_PER_DAY = 86400; //24 * 60 * 60

    uint256 constant MAX_SUPPLY = 100;

    uint256 internal lastMintedId = 0;

    //Publicly accessible list of goblet owners
    mapping(uint256 => GobletOwnership) public gobletOwners;

    constructor() {
        INITIAL_DATE = block.timestamp;
        console.log("Init Goblet success");
    }

    function addGobletOwner(address customerAddress)
        internal
        returns (uint256 gobletId)
    {
        require(lastMintedId + 1 < MAX_SUPPLY, "No Goblet supply");
        //Revert if current year is past the validity period, eg: user tries to mint in year 2026, but validity is till 2025
        require(
            getYear(INITIAL_DATE + VALIDITY_PERIOD) > getYear(block.timestamp),
            "Goblets cannot be minted anymore"
        );

        GobletOwnership memory gobletOwnership = GobletOwnership(
            customerAddress,
            lastMintedId + 1,
            block.timestamp
        );
        gobletOwners[lastMintedId + 1] = gobletOwnership;
        lastMintedId++;

        return lastMintedId;
    }

    function isGobletMintedThisYear(address user)
        internal
        view
        returns (bool isMintedThisYear)
    {
        for (uint64 i = 0; i < lastMintedId; i++) {
            if (gobletOwners[i].owner == user) {
                if (
                    getGobletMintedYear(gobletOwners[i].mintedDate) ==
                    getGobletMintedYear(block.timestamp)
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function getGobletMintedYear(uint256 gobletId)
        internal
        view
        returns (uint256)
    {
        GobletOwnership memory gobletOwnership = gobletOwners[gobletId];
        return getYear(gobletOwnership.mintedDate);
    }

    function getYear(uint256 timestamp) internal pure returns (uint256) {
        return _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function _daysToDate(uint256 _days) internal pure returns (uint256 year) {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + 2440588; //Offset
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        L = _month / 11;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
    }
}
