// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;
    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new MyToken();
        token.mint(address(this), 1000);
    }

    function testMint() public {
        token.mint(user1, 100);
        assertEq(token.balanceOf(user1), 100);
    }

    function testTransfer() public {
        token.transfer(user1, 200);
        assertEq(token.balanceOf(user1), 200);
        assertEq(token.balanceOf(address(this)), 800);
    }

    function testTransferToAnotherUser() public {
        token.transfer(user1, 100);

        vm.prank(user1);
        token.transfer(user2, 50);

        assertEq(token.balanceOf(user2), 50);
    }

    function testApprove() public {
        token.approve(user1, 300);
        assertEq(token.allowance(address(this), user1), 300);
    }

    function testTransferFrom() public {
        token.approve(user1, 100);

        vm.prank(user1);
        token.transferFrom(address(this), user1, 100);

        assertEq(token.balanceOf(user1), 100);
    }

    function testTransferFromReducesAllowance() public {
        token.approve(user1, 100);

        vm.prank(user1);
        token.transferFrom(address(this), user1, 50);

        assertEq(token.allowance(address(this), user1), 50);
    }

    function testRevertTransferWithoutBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 10);
    }

    function testRevertTransferFromWithoutApproval() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(address(this), user2, 10);
    }

    function testMultipleTransfers() public {
        token.transfer(user1, 100);
        token.transfer(user2, 200);

        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(user2), 200);
        assertEq(token.balanceOf(address(this)), 700);
    }

    function testZeroTransfer() public {
        token.transfer(user1, 0);
        assertEq(token.balanceOf(user1), 0);
    }

    function testFuzzTransfer(address to, uint256 amount) public {
        amount = bound(amount, 0, 1000);

        token.transfer(to, amount);
        assertEq(token.balanceOf(to), amount);
    }
}