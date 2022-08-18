//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import {GemstoneMinter} from "./GemstoneMinter.sol";
import {Types} from "./libs/Types.sol";

contract Goblet {
    struct GobletOwnership {
        address owner;
        uint256 gobletId;
        uint256 mintedDate; // Set with block.timestamp
    }

    uint256 constant VALIDITY_PERIOD = 31556952; //3 Years

    uint256 immutable INITIAL_DATE; //3 Years

    uint256 constant SECONDS_PER_DAY = 86400; //24 * 60 * 60

    uint256 constant MAX_SUPPLY = 150;

    uint256 internal lastMintedId = 0;

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
        require(
            INITIAL_DATE + VALIDITY_PERIOD > block.timestamp,
            "Goblets cannot be minted anymore"
        );

        GobletOwnership memory gobletOwnership = GobletOwnership(
            customerAddress,
            lastMintedId + 1,
            block.timestamp
        );
        gobletOwners[lastMintedId + 1] = gobletOwnership;
        lastMintedId++;

        return lastMintedId; // returns the ID of the goblet minted 
    }

    //TODO Function to get date of owned goblet
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
