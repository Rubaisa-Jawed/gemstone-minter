//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {GemstoneMinter} from "./GemstoneMinter.sol";
import "./Goblet.sol";

contract GobletMinter is Goblet, ERC1155 {
    address gemstoneContract = 0x8fDB766E5d8D27A87534Eac7a8A34C7602b22210;

    //This is for opensea contract name display
    string public name = "Malt, Grain & Cane Infinity Goblet";

    error GobletMintedThisYear();
    error InEligibleToMintGoblet();

    constructor() ERC1155("") {
        console.log("Init GobletMinter success");
    }

    //Function to mint goblet (gemstoneContract address to be hardcoded after testing)
    function mintGoblet(address customerAddress) public payable {
        if (isGobletMintedThisYear(customerAddress)) {
            revert GobletMintedThisYear();
        }
        GemstoneMinter gm = GemstoneMinter(gemstoneContract);
        if (!gm.isEligibleToMintGoblet(customerAddress)) {
            revert InEligibleToMintGoblet();
        }
        uint256 gobletId = addGobletOwner(customerAddress);
        _mint(customerAddress, gobletId, 1, "");
        gm.redeemGemstonesForGoblet(customerAddress);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "ipfs://QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj/",
                    Strings.toString(id),
                    "_",
                    Strings.toString(getGobletMintedYear(id)),
                    ".json"
                )
            );
    }
}
