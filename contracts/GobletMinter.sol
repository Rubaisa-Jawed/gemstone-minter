//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {GemstoneMinter} from "./GemstoneMinter.sol";
import "./Goblet.sol";

contract GobletMinter is Goblet, ERC1155 {
    // commented out for testing purposes
    // address gemstoneContract = 0x309dd80e29AB87b553592DC0c4938562adfAB3C9;

    //This is for opensea contract name display
    string public name = "Malt Grain & Cane Whiskey";

    constructor() ERC1155("") {
        console.log("Init GemstoneMinter success");
    }

    //Function to mint goblet (gemstoneContract address to be hardcoded after testing)
    function mintGoblet(address customerAddress, address gemstoneContract) public payable {
        GemstoneMinter gm = GemstoneMinter(gemstoneContract);
        require(
            gm.isEligibleToMintGoblet(customerAddress),
            "Not eligible to mint goblet"
        );
        uint256 gobletId = addGobletOwner(customerAddress);
        _mint(customerAddress, gobletId, 1, "");
        gm.redeemGemstonesForGoblet(customerAddress);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
        string(
            abi.encodePacked(
                "ipfs://QmdReKfc8SFq4Z8YQREfhK7Lpws3v1xvCVXUVfewaDeVz5/",
                Strings.toString(getGobletMintedYear(id)),
                "_",
                Strings.toString(id),
                ".json"
            )
        );
    }
}
