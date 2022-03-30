// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

library Types {
    enum GemstoneType {
        Amethyst, //Purple
        Sapphire, //Blue
        Emerald, //Green
        Citrine, //Yellow
        Amber, //Orange
        Ruby //Red
    }

    struct Gemstone {
        GemstoneType gemstone;
        uint8 supply; //50
        uint8 lastMintedId; //1-50, INIT IS 0
    }

    struct PurchaseInfo {
        GemstoneType gemstoneType;
        uint8 gemId;
        uint256 purchasedDate; // Set with block.timestamp
        uint256 validityDate; // Set with block.timestamp + VALIDITY_PERIOD
        bool redeemed;
    }
}
