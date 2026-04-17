// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract InvariantTest is Test {
    MyToken token;
    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new MyToken();

        token.mint(address(this), 1000);
        token.mint(user1, 500);
        token.mint(user2, 500);
    }

    // ✅ totalSupply всегда >= сумме балансов
    function invariant_totalSupplyConsistency() public {
        uint256 totalBalances =
            token.balanceOf(address(this)) +
            token.balanceOf(user1) +
            token.balanceOf(user2);

        assertTrue(token.totalSupply() >= totalBalances);
    }

    // ✅ баланс никогда не превышает totalSupply
    function invariant_balanceNeverExceedsTotalSupply() public {
        uint256 total = token.totalSupply();

        assertTrue(token.balanceOf(address(this)) <= total);
        assertTrue(token.balanceOf(user1) <= total);
        assertTrue(token.balanceOf(user2) <= total);
    }
}