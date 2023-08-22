// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is Ownable {
    struct Listing {
        address nftContract;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isForSale;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId = 0;
    uint256 public marketFeePercent; // Market fee as a percentage
    uint256 public collectedFees; // Total collected fees

    event NFTListed(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        address indexed seller
    );
    event NFTDelisted(uint256 indexed listingId);
    event NFTPurchased(
        uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 price
    );

    /**
     * @notice A contract for listing and purchasing NFTs with a market fee
     * @dev Constructor sets the initial market fee percentage
     * @param _marketFeePercent The market fee as a percentage (0-100)
     */
    constructor(uint256 _marketFeePercent) {
        require(_marketFeePercent <= 100, "Fee must be <= 100");
        marketFeePercent = _marketFeePercent;
    }

    /**
     * @notice Set the market fee percentage
     * @param _marketFeePercent The market fee as a percentage (0-100)
     */
    function setMarketFeePercent(uint256 _marketFeePercent) external onlyOwner {
        require(_marketFeePercent <= 100, "Fee must be <= 100");
        marketFeePercent = _marketFeePercent;
    }

    /**
     * @notice List an NFT for sale
     * @param nftContract The address of the NFT's contract
     * @param tokenId The ID of the NFT
     * @param price The listing price in Ether
     */
    function listNFT(address nftContract, uint256 tokenId, uint256 price) public {
        // Check that the caller is the owner of the NFT
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not the owner");
        // Price must be greater than 0
        require(price > 0, "Price must be greater than 0");

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing(nftContract, tokenId, price, msg.sender, true);
        // Transferring the NFT to the contract's custody until purchase
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(listingId, nftContract, tokenId, price, msg.sender);
    }

    /**
     * @notice Purchase an NFT from a listing
     * @dev This function also handles fee calculation and distribution
     * @param listingId The ID of the listing to purchase
     */
    function fulfillListing(uint256 listingId) external payable {
        // Check that the listing is active and for sale
        require(listings[listingId].isForSale, "Not for sale");
        // The sent value must match the listing price
        require(msg.value == listings[listingId].price, "Incorrect price");

        Listing memory listing = listings[listingId];

        uint256 fee = (listing.price * marketFeePercent) / 100; // Calculating the marketplace fee
        uint256 sellerProceeds = listing.price - fee; // The amount to be sent to the seller

        // Prevent reentrancy by setting isForSale to false before any external calls
        listing.isForSale = false;
        listings[listingId] = listing;

        // Transfer the NFT to the buyer
        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);
        // Transfer the proceeds to the seller
        (bool sent,) = payable(listing.seller).call{value: sellerProceeds}("");
        require(sent, "Failed to send Ether");

        // total the collected fees
        collectedFees += fee;

        emit NFTPurchased(listingId, msg.sender, listing.seller, listing.price);
    }

    /**
     * @notice Delist an NFT, stopping it from being sold
     * @param listingId The ID of the listing to delist
     */
    function delistNFT(uint256 listingId) public {
        // save gas by copying to memory
        Listing memory listing = listings[listingId];

        // Check that the caller is the seller of the NFT
        require(listing.seller == msg.sender, "Not the seller");
        // Check that the listing is active and for sale
        require(listing.isForSale, "Not listed");

        // Prevent reentrancy by setting isForSale to false before any external calls
        listing.isForSale = false;
        // Update the listing in storage
        listings[listingId] = listing;

        // Transfer the NFT back to the seller
        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);

        emit NFTDelisted(listingId);
    }

    /**
     * @notice Withdraw the accumulated market fees
     * @dev Only callable by the owner
     */
    function withdrawFees() external onlyOwner {
        uint256 fees = collectedFees;
        collectedFees = 0;
        (bool sent,) = payable(owner()).call{value: fees}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice Retrieve information about a specific listing
     * @param listingId The ID of the listing
     * @return Listing information including contract address, token ID, price, and seller
     */
    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }

    receive() external payable {}
}
