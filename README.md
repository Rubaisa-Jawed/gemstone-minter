# Gemstone generator for Multi Grain & Cane Whiskey

- ERC1155 #1:
  - 6 different token types (6 different gem stones)
  - 50 of each token (6x50 = 300 tokens total supply), but all are NFTs (so all have different #IDs; for example #1-#50 is type 1, #51-100 is type 2, etc.)
  - Address must be whitelisted for a specific address in order to mint a gemstone NFT of a specific type
  - Addresses will be whitlelisted by client
  - max 1 token type mint per address (i.e. user A can only mint 1x gemstone A)
  - Gemstone tokens must have a property to keep track of whether it’s been used to redeem a goblet or not (`redeemed` property)
  - 1-1.5 weeks turnaround time (because launch was already delayed)
- ERC1155 #2:
  - 1 token type, the gemstone goblet
  - users can use 6 unused gemstones to mint 1 goblet
  - for the next 3 or so (TBD) years, users can mint ‘REPLICA’ goblets every year (each year will have different art)

WIP Minted: https://testnets.opensea.io/collection/unidentified-contract-j8thcwgiuh

Useful scripts:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
