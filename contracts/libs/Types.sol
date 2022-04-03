// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

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
        uint256 supply; //50
        uint256 lastMintedId; //1-50, INIT IS 0
    }

    struct PurchaseInfo {
        GemstoneType gemstoneType;
        uint256 gemId;
        uint256 purchasedDate; // Set with block.timestamp
        uint256 validityDate; // Set with block.timestamp + VALIDITY_PERIOD
        bool redeemed;
    }
}
