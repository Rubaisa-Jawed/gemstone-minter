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

    uint256 private constant VALIDITY_PERIOD = 1790812799; // LAST MINT IS SEP_30_2026 (23:59:59)

    uint256 private immutable INITIAL_DATE; //Date of contract deployment (2022)

    uint256 private constant SECONDS_PER_DAY = 86400; //24 * 60 * 60

    uint256 constant MAX_SUPPLY = 200;

    uint256 internal lastMintedId = 0;

    //Publicly accessible list of goblet owners
    // maps from goblet ID to GobletOwnership struct 
    mapping(uint256 => GobletOwnership) public gobletOwners;

    error GobletSupplyExhausted();
    error MintPeriodOver();

    constructor() {
        INITIAL_DATE = block.timestamp;
        console.log("Init Goblet success");
    }

    function addGobletOwner(address customerAddress)
        internal
        returns (uint256 gobletId)
    {
        if (lastMintedId + 1 > MAX_SUPPLY) {
            revert GobletSupplyExhausted();
        }
        // Revert if current time is after the final mint date. 
        if (
            block.timestamp > VALIDITY_PERIOD
        ) {
            revert MintPeriodOver();
        }

        GobletOwnership memory gobletOwnership = GobletOwnership(
            customerAddress,
            lastMintedId + 1,
            block.timestamp
        );
        gobletOwners[lastMintedId + 1] = gobletOwnership;
        lastMintedId++;

        return lastMintedId; // returns the ID of the goblet minted 
    }

    function isGobletMintedThisYear(address user)
        internal
        view
        returns (bool isMintedThisYear)
    {
        for (uint64 i = 0; i < lastMintedId; i++) {
            if (gobletOwners[i].owner == user) {
                if (
                    getYear(gobletOwners[i].mintedDate) ==
                    getYear(block.timestamp)
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function getGobletMintedPeriod(uint256 gobletId)
        internal
        view
        returns (uint256)
    {
        GobletOwnership memory gobletOwnership = gobletOwners[gobletId]; 

        // ORIGINAL GOBLET CAN BE MINTED FROM: 01SEP2022 (00:00) - 30SEP2023 (23:59:59)
        // SECOND GOBLET CAN BE MINTED FROM: 01OCT2023 (00:00) - 30SEPT2024 (23:59:59)
        // THIRD GOBLET CAN BE MINTED FROM: 01OCT2024 (00:00) - 30SEPT2025 (23:59:59)
        // FOURTH GOBLET CAN BE MINTED FROM: 01OCT2025 (00:00) - 30SEPT2026 (23:59:59)
        uint SEP_01_2022 = 1661990400; // (00:00:00)
        uint SEP_30_2023 = 1696118399; // (23:59:59)
        uint SEP_30_2024 = 1727740799; // (23:59:59)
        uint SEP_30_2025 = 1759276799; // (23:59:59)
        uint SEP_30_2026 = 1790812799; // (23:59:59)
        console.log(block.timestamp);
        if (gobletOwnership.mintedDate >= SEP_01_2022 && gobletOwnership.mintedDate <= SEP_30_2023) {
            return 2022;
        } else if (gobletOwnership.mintedDate <= SEP_30_2024) {
            return 2023;
        } else if (gobletOwnership.mintedDate <= SEP_30_2025) {
            return 2024;
        } else if (gobletOwnership.mintedDate <= SEP_30_2026) {
            return 2025;
        }

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
