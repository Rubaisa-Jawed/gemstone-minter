// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

library Types {
    enum GemstoneType {
        Azure,
        Lapis,
        Saphirre,
        Emerald,
        Ruby,
        Diamond,
        Goblet
    }

    struct Gemstone {
        GemstoneType gemstone;
        uint8 supply;
        uint8 lastMintedId;
    }

    struct PurchaseInfo {
        GemstoneType gemstoneType;
        uint8 gemId;
        uint256 purchasedDate; // Set with block.timestamp or from client
        uint256 validityDate;
        bool redeemed;
    }
}
