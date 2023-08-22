// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AtomicSwap.sol";
import "../src/MockERC20.sol";

contract AtomicSwapTest is Test {
    AtomicSwap public atomicSwap;
    // Set users
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);

    // Mock tokens
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    bytes32 public swapId;

    function setUp() public {
        atomicSwap = new AtomicSwap();

        // Initialize mock tokens
        tokenA = new MockERC20("ERC20A", "A");
        tokenB = new MockERC20("ERC20B", "B");

        // Example swap details
        uint256 amountA = 100;
        uint256 amountB = 200;

        //deal amounts to users
        tokenA.mint(user1, amountA);
        tokenB.mint(user2, amountB);

        //approve tokens to be spent by atomicSwap
        vm.prank(user1);
        tokenA.approve(address(atomicSwap), amountA);

        vm.prank(user2);
        tokenB.approve(address(atomicSwap), amountB);

        // Calculate swap ID
        swapId = keccak256(
            abi.encodePacked(user1, user2, address(tokenA), address(tokenB), amountA, amountB)
        );
    }

    function testInitiateSwap() public {
        // check balances of users
        assertEq(tokenA.balanceOf(user1), 100);
        assertEq(tokenB.balanceOf(user2), 200);

        // Initiate a swap
        vm.prank(user1);
        atomicSwap.initiateSwap(user2, address(tokenA), address(tokenB), 100, 200);

        // Verify the swap details
        (
            bool isAccepted,
            address userA,
            address userB,
            address tokenAAddr,
            address tokenBAddr,
            uint256 amountA,
            uint256 amountB
        ) = atomicSwap.swaps(swapId);

        assertEq(userA, user1);
        assertEq(userB, user2);
        assertEq(tokenAAddr, address(tokenA));
        assertEq(tokenBAddr, address(tokenB));
        assertEq(amountA, 100);
        assertEq(amountB, 200);
        assert(!isAccepted);
    }

    function testAcceptSwap() public {
        // check balances of users
        assertEq(tokenA.balanceOf(user1), 100);
        assertEq(tokenB.balanceOf(user2), 200);

        // Initiate a swap
        vm.prank(user1);
        atomicSwap.initiateSwap(user2, address(tokenA), address(tokenB), 100, 200);

        // have wrong user attempt to accept the swap
        vm.prank(user3);
        vm.expectRevert();
        atomicSwap.acceptSwap(swapId);

        // Accept the swap
        vm.prank(user2);
        atomicSwap.acceptSwap(swapId);

        // Verify that the swap is accepted
        AtomicSwap.Swap memory swap = atomicSwap.getSwap(swapId);
        assert(swap.isAccepted);

        // Verify that the tokens are swapped
        assertEq(tokenA.balanceOf(user1), 0);
        assertEq(tokenB.balanceOf(user2), 0);
        assertEq(tokenA.balanceOf(user2), 100);
        assertEq(tokenB.balanceOf(user1), 200);
    }

    //test cancel swap
    function testCancelSwap() public {
        // check balances of users
        assertEq(tokenA.balanceOf(user1), 100);
        assertEq(tokenB.balanceOf(user2), 200);

        // Initiate a swap
        vm.prank(user1);
        atomicSwap.initiateSwap(user2, address(tokenA), address(tokenB), 100, 200);

        // Cancel the swap
        vm.prank(user1);
        atomicSwap.cancelSwap(swapId);

        // Verify that the swap is cancelled
        AtomicSwap.Swap memory swap = atomicSwap.getSwap(swapId);
        assertEq(swap.userA, address(0));

        //try to accept the swap
        vm.prank(user2);
        vm.expectRevert();
        atomicSwap.acceptSwap(swapId);
    }
}
