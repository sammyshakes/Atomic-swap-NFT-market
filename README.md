
# Solidity Contracts Repository for Shakespeare Interview

This repository contains two Solidity smart contracts: `NFTMarket` and `AtomicSwap`. These contracts allow for decentralized trading of non-fungible tokens (NFTs) and Atomic swaps of ERC20 tokens, respectively.

## NFTMarket

The `NFTMarket` contract is a decentralized marketplace for buying and selling NFTs. Users can list their NFTs for sale and purchase others in a secure and transparent manner.

### Features

- **Sell NFTs:** Owners can list their NFTs at a specific price.
- **Buy NFTs:** Buyers can purchase listed NFTs.
- **Delist NFTs:** Sellers can remove their NFTs from the marketplace.
- **Market Fee:** A configurable market fee percentage is taken from each sale.

### Usage

To interact with the contract, one can use the following primary functions:

- `listNFT(address nftContract, uint256 tokenId, uint256 price)`
- `delistNFT(uint256 listingId)`
- `fulfillListing(uint256 listingId)`

## AtomicSwap

The `AtomicSwap` contract enables trustless swapping of ERC20 tokens between two parties. This contract ensures that both sides of the trade are fulfilled, or the transaction is reverted.

### Features

- **Initiate Swap:** User A can initiate a swap with specified tokens and amounts.
- **Accept Swap:** User B can accept the initiated swap.
- **Cancel Swap:** User A can cancel the swap before it's accepted.

### Usage

To initiate, accept, or cancel a swap, the following functions are available:

- `initiateSwap(address userB, address tokenA, address tokenB, uint256 amountA, uint256 amountB)`
- `initiateSwap(address userB, address tokenA, address tokenB, uint256 amountA, uint256 amountB, bytes32 salt)`
- `acceptSwap(bytes32 swapId)`
- `cancelSwap(bytes32 swapId)`

## Installation

These contracts are written in Solidity and tested with Foundry framework.

[Foundry install instructions](https://book.getfoundry.sh/getting-started/installation)

Once Foundry is installed, it is a good idea to run `foundryup` in connamd line:

```bash
foundryup
```

Clone this repo, cd into project folder and run `forge install`:

```bash
git clone ...
cd Eigenlayer-interview
forge install
```

Run tests:
```bash
forge test 
```

To see traces:
```bash
forge test -vvvv
```




## Contributions

Contributions, issues, and feature requests are welcome!
