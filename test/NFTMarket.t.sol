// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/MockERC721.sol";
import "../src/NFTMarket.sol";

contract TestNFTMarket is Test {
    NFTMarket public market;
    MockERC721 public token;

    // Set users
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public owner = address(0x4);

    // Mock tokenid for general use
    uint256 public tokenId = 1;
    uint256 public marketFeePercent = 5;

    function setUp() public {
        vm.startPrank(owner);
        token = new MockERC721("Test Token", "TT");
        market = new NFTMarket(marketFeePercent); // Setting a 5% market fee

        // deal amounts to users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 200 ether);

        // Minting token id 1 to user1
        token.mint(user1, tokenId);
        vm.stopPrank();
    }

    function testListingNFT() public {
        uint256 listingPrice = 10 ether;

        // Approve the market contract to transfer the token
        vm.startPrank(user1);
        token.approve(address(market), tokenId);
        market.listNFT(address(token), tokenId, listingPrice);
        vm.stopPrank();

        (address nftContract,, uint256 price,, bool isForSale) = market.listings(0);
        assertEq(nftContract, address(token), "NFT contract address mismatch");
        assertEq(price, listingPrice, "Price mismatch");
        assertTrue(isForSale, "Should be listed for sale");
    }

    function testDelistingNFT() public {
        uint256 listingPrice = 10 ether;

        // Approve the market contract
        vm.startPrank(user1);
        token.approve(address(market), tokenId);
        market.listNFT(address(token), tokenId, listingPrice);
        market.delistNFT(0);

        (,,,, bool isForSale) = market.listings(0);
        assertFalse(isForSale, "Should be delisted");
    }

    function testFulfillListing() public payable {
        // Record user1 balance before
        uint256 user1BalanceBefore = user1.balance;

        uint256 listingPrice = 10 ether;

        // user1 lists the token
        vm.startPrank(user1);
        token.approve(address(market), tokenId);
        market.listNFT(address(token), tokenId, listingPrice);
        vm.stopPrank();

        // user2 fulfills the listing
        vm.prank(user2);
        market.fulfillListing{value: listingPrice}(0);

        // Verify the state after the sale
        address newOwner = token.ownerOf(tokenId);
        assertEq(newOwner, user2, "New owner should be user2");

        uint256 marketFee = listingPrice * marketFeePercent / 100;
        assertEq(market.collectedFees(), marketFee, "Market fee should be collected");

        uint256 sellerAmount = listingPrice - marketFee;
        assertEq(
            user1.balance, sellerAmount + user1BalanceBefore, "Seller should receive the amount"
        );

        (,,,, bool isForSale) = market.listings(0);
        assertFalse(isForSale, "Should be delisted");
    }

    function testMarketFee() public {
        assertEq(market.marketFeePercent(), 5, "Market fee should be 5%");
    }

    //test withdraw fees
    function testWithdrawFees() public {
        uint256 listingPrice = 10 ether;

        // setup a list and a sale to collect some fees
        vm.startPrank(user1);
        token.approve(address(market), tokenId);
        market.listNFT(address(token), tokenId, listingPrice);
        vm.stopPrank();

        vm.prank(user2);
        market.fulfillListing{value: listingPrice}(0);

        uint256 marketFee = listingPrice * marketFeePercent / 100;
        assertEq(market.collectedFees(), marketFee, "Market fee amount invalid");

        // withdraw fees
        vm.prank(owner);
        market.withdrawFees();

        // Verify fees have been withdrawn
        assertEq(market.collectedFees(), 0, "Market fees collected should be 0");
    }

    // fuzz tests for listingPrice and tokenId
    function testFuzz(uint256 _tokenId, uint256 _listPrice) public {
        // fuzz assumptions
        vm.assume(_tokenId != 1);
        vm.assume(_listPrice > 0);
        vm.assume(_listPrice <= 100 ether);

        // Minting fuzzed token id to user1
        vm.startPrank(owner);
        token.mint(user1, _tokenId);
        vm.stopPrank();

        // Record user1 balance before
        uint256 user1BalanceBefore = user1.balance;

        // fuzzed list price
        uint256 listingPrice = _listPrice;

        // user1 lists the token
        vm.startPrank(user1);
        token.approve(address(market), _tokenId);
        market.listNFT(address(token), _tokenId, listingPrice);
        vm.stopPrank();

        // user2 fulfills the listing
        vm.prank(user2);
        market.fulfillListing{value: listingPrice}(0);

        // Verify the state after the sale
        address newOwner = token.ownerOf(_tokenId);
        assertEq(newOwner, user2, "New owner should be user2");

        uint256 marketFee = listingPrice * marketFeePercent / 100;
        assertEq(market.collectedFees(), marketFee, "Market fee should be collected");

        uint256 sellerAmount = listingPrice - marketFee;
        assertEq(
            user1.balance, sellerAmount + user1BalanceBefore, "Seller should receive the amount"
        );

        (,,,, bool isForSale) = market.listings(0);
        assertFalse(isForSale, "Should be delisted");
    }

    function testGetUserTransactions() public {
        uint256 listingPrice = 10 ether;

        // User1 lists the token
        vm.startPrank(user1);
        token.approve(address(market), tokenId);
        market.listNFT(address(token), tokenId, listingPrice);
        vm.stopPrank();

        // User2 fulfills the listing
        vm.prank(user2);
        market.fulfillListing{value: listingPrice}(0);

        // Get the transactions for user1
        uint256[] memory user1Transactions = market.getUserTransactions(user1);

        // Check that there's only one transaction for user1
        assertEq(user1Transactions.length, 1, "User1 should have one transaction");

        // Get the transactions for user2
        uint256[] memory user2Transactions = market.getUserTransactions(user2);

        // Check that there's only one transaction for user2
        assertEq(user2Transactions.length, 1, "User2 should have one transaction");
    }
}
