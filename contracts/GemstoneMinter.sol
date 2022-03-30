//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Gemstone.sol";
import {Types} from "./libs/Types.sol";

contract GemstoneMinter is Gemstone, ERC1155 {
    constructor() ERC1155("") {
        console.log("Init GemstoneMinter success");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /*
        Add address to whitelist for a gemstone type and purchase the gemstone for address
        @param customerAddress address of customer
        @param gemstoneType gemstone type
        Range of gemstone type is defined in Types.sol (0..5)
        Sets redeemed as false by default
        The mint id is by series of increasing id, matching the metadata
        0-50 for gemstone type 0
        100-150 for gemstone type 1
        ...
    */
    function mint(address customerAddress, uint8 gemstoneType)
        public
        payable
        onlyOwner
    {
        require(isGemstoneAvailable(gemstoneType), "Gemstone not available");
        require(
            !isGemstoneMinted(customerAddress, gemstoneType),
            "Gemstone already minted"
        );
        addToWhitelist(customerAddress, gemstoneType);
        uint8 gemId = recordPurchase(customerAddress, gemstoneType);
        uint8 mintId = gemstoneType * 100 + gemId;
        addToRedeemedWithDefault(mintId);
        _mint(customerAddress, mintId, 1, "");
        console.log("Minted: ", Strings.toString(mintId));
    }

    /*
        Public function to be called by contract owner to mint a goblet
        It returns true after setting all the gemstones as redeemed
        False if user fails condition to mint goblet
    */
    function redeemGemstonesForGoblet(address customerAddress)
        public
        returns (bool)
    {
        return redeemPurchasesForGoblet(customerAddress);
    }

    //View fns

    function getOwner() public view returns (address) {
        return getOwnerAddress();
    }

    //Returns purchases for a customer
    //Adding for future use by contract #2
    function getPurchasesOfCustomer(address customerAddress)
        public
        view
        returns (Types.PurchaseInfo[] memory purchases)
    {
        return getPurchasesOfUser(customerAddress);
    }

    //Returns purchases for the contract
    //Adding for future use by contract #2
    function getAllPurchases()
        public
        view
        returns (Types.PurchaseInfo[] memory purchaseInfos)
    {
        return getPurchases();
    }

    /*
        Returns uri for marketplaces
        We maintain 2 stores for metadata
        #1 For redeemed (Will be returned for items which are not redeemed)
        #2 For unredeemed (Default state)
        @param customerAddress address of customer
        @param gemstoneType gemstone type
        Range of gemstone type is defined in Types.sol (0..5)
    */
    function uri(uint256 id) public view override returns (string memory) {
        if (!isGemRedeemedForId(uint8(id))) {
            return
                string(
                    abi.encodePacked(
                        "ipfs://QmZAUTZMnabb2Q4qi7eoAhjUn3imSK6bpKHrA3qpe3Xo7i/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Not redeemed ipfs
        } else {
            return
                string(
                    abi.encodePacked(
                        "ipfs://QmcsNr2hgitfpCrcUATsanPyxGf2RXbRzkFPczRSKD9fbz/",
                        Strings.toString(id),
                        ".json"
                    )
                ); //Redeemed ipfs
        }
    }

    //TODO Remove after testing
    //Not required here
    function redeemGemstoneExperimental(address customerAddress, uint8 gemId)
        public
        onlyOwner
    {
        redeemGemstone(customerAddress, gemId);
    }
}
