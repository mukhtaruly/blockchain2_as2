// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/AMM.sol";

contract AMMTest is Test {
    MyToken tokenA;
    MyToken tokenB;
    AMM amm;

    address user = address(1);

    function setUp() public {
        tokenA = new MyToken();
        tokenB = new MyToken();

        amm = new AMM(address(tokenA), address(tokenB));

        // mint токены
        tokenA.mint(address(this), 1e24);
        tokenB.mint(address(this), 1e24);

        tokenA.mint(user, 1e24);
        tokenB.mint(user, 1e24);

        // approve
        tokenA.approve(address(amm), 1e24);
        tokenB.approve(address(amm), 1e24);

        vm.prank(user);
        tokenA.approve(address(amm), 1e24);

        vm.prank(user);
        tokenB.approve(address(amm), 1e24);
    }

    // ✅ ADD LIQUIDITY

    function testAddLiquidity() public {
        amm.addLiquidity(100, 100);

        assertEq(amm.reserveA(), 100);
        assertEq(amm.reserveB(), 100);
    }

    function testAddLiquiditySecondUser() public {
        amm.addLiquidity(100, 100);

        vm.prank(user);
        amm.addLiquidity(50, 50);

        assertEq(amm.reserveA(), 150);
        assertEq(amm.reserveB(), 150);
    }

    function testRemoveLiquidity() public {
        amm.addLiquidity(100, 100);

        amm.removeLiquidity(100);

        assertEq(amm.reserveA(), 0);
        assertEq(amm.reserveB(), 0);
    }

    function testPartialRemoveLiquidity() public {
        amm.addLiquidity(200, 200);

        amm.removeLiquidity(100);

        assertEq(amm.reserveA(), 100);
        assertEq(amm.reserveB(), 100);
    }

    // ❗ REVERT TESTS (исправленные)

    function testRevertSwapZero() public {
        vm.expectRevert();
        amm.swap(address(tokenA), 0);
    }

    function testRevertRemoveTooMuch() public {
        amm.addLiquidity(100, 100);

        vm.expectRevert();
        amm.removeLiquidity(1000);
    }

    // ✅ SWAP

    function testSwapAtoB() public {
        amm.addLiquidity(1000, 1000);

        tokenA.approve(address(amm), 100);
        amm.swap(address(tokenA), 100);

        assertGt(tokenB.balanceOf(address(this)), 0);
    }

    function testSwapBtoA() public {
        amm.addLiquidity(1000, 1000);

        tokenB.approve(address(amm), 100);
        amm.swap(address(tokenB), 100);

        assertGt(tokenA.balanceOf(address(this)), 0);
    }

    // ✅ K INVARIANT

    function testKInvariant() public {
        amm.addLiquidity(1000, 1000);

        uint256 kBefore = amm.reserveA() * amm.reserveB();

        tokenA.approve(address(amm), 100);
        amm.swap(address(tokenA), 100);

        uint256 kAfter = amm.reserveA() * amm.reserveB();

        assertGe(kAfter, kBefore);
    }

    // ✅ EDGE CASE

    function testLargeSwap() public {
        amm.addLiquidity(1000, 1000);

        tokenA.approve(address(amm), 900);
        amm.swap(address(tokenA), 900);

        assertGt(tokenB.balanceOf(address(this)), 0);
    }

    // ✅ FUZZ

    function testFuzzSwap(uint256 amount) public {
        amount = bound(amount, 1, 100);

        amm.addLiquidity(1000, 1000);

        tokenA.approve(address(amm), amount);
        amm.swap(address(tokenA), amount);

        assertGt(tokenB.balanceOf(address(this)), 0);
    }
}