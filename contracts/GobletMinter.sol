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

    string public metadataCID = "QmSczXio2CCNkcTwbJPmHqbPv6oSv1C1ax61ebQuWhTLFj";

    address immutable owner; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    error GobletMintedThisYear();
    error InEligibleToMintGoblet();

    constructor() ERC1155("") {
        owner = msg.sender;
        console.log("Init GobletMinter success");
    }

    //Function to mint goblet (gemstoneContract address to be hardcoded after testing)
    function mintGoblet() public payable {
        if (isGobletMintedThisYear(msg.sender)) {
            revert GobletMintedThisYear();
        }

        GemstoneMinter gm = GemstoneMinter(gemstoneContract);
        if (!gm.redeemGemstonesForGoblet(msg.sender)) {
            // `redeemGemstonesForGoblet` automatically checks whether the caller is eligible. If they are not, it will fail and return false. 
            revert InEligibleToMintGoblet();
        }
        uint256 gobletId = addGobletOwner(msg.sender);
        _mint(msg.sender, gobletId, 1, "");
    }

    /* 
        Function to update the CID of the goblets metadata.
        @param _cid is the new CID of the metadata.
    */
    function updateCID(string calldata _cid) public onlyOwner {
        metadataCID = _cid;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "ipfs://",
                    metadataCID,
                    "/",
                    Strings.toString(id),
                    "_",
                    Strings.toString(getGobletMintedYear(id)),
                    ".json"
                )
            );
    }
}
