// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/LendingPool.sol";

contract LendingTest is Test {
    MyToken token;
    LendingPool pool;

    address user = address(1);

    function setUp() public {
        token = new MyToken();
        pool = new LendingPool(address(token));

        token.mint(address(this), 1e24);
        token.mint(user, 1e24);

        token.approve(address(pool), 1e24);

        vm.prank(user);
        token.approve(address(pool), 1e24);
    }

    // ✅ DEPOSIT

    function testDeposit() public {
        pool.deposit(100);
        assertEq(pool.deposits(address(this)), 100);
    }

    // ✅ BORROW

    function testBorrowWithinLTV() public {
        pool.deposit(100);
        pool.borrow(50);
        assertEq(pool.borrows(address(this)), 50);
    }

    function testRevertBorrowTooMuch() public {
        pool.deposit(100);

        vm.expectRevert();
        pool.borrow(80);
    }

    // ✅ REPAY

    function testRepay() public {
        pool.deposit(100);
        pool.borrow(50);

        pool.repay(50);

        assertEq(pool.borrows(address(this)), 0);
    }

    function testPartialRepay() public {
        pool.deposit(100);
        pool.borrow(50);

        pool.repay(20);

        assertEq(pool.borrows(address(this)), 30);
    }

    // ✅ WITHDRAW

    function testWithdraw() public {
        pool.deposit(100);
        pool.withdraw(50);
        assertEq(pool.deposits(address(this)), 50);
    }

    function testRevertWithdrawWithDebt() public {
        pool.deposit(100);
        pool.borrow(70);

        vm.expectRevert();
        pool.withdraw(50);
    }

    // ✅ LIQUIDATION (финальный правильный вариант)

    function testLiquidation() public {
        // даём пулу ликвидность
        token.mint(address(pool), 1000);

        vm.startPrank(user);

        pool.deposit(100);
        pool.borrow(75); // ровно на границе

        vm.stopPrank();

        // liquidation должен сработать при >=
        pool.liquidate(user);

        assertEq(pool.deposits(user), 0);
        assertEq(pool.borrows(user), 0);
    }

    // ✅ EDGE CASE

    function testRevertBorrowWithoutDeposit() public {
        vm.expectRevert();
        pool.borrow(10);
    }

    // ✅ FUZZ

    function testFuzzDeposit(uint256 amount) public {
        amount = bound(amount, 1, 1000);

        pool.deposit(amount);

        assertEq(pool.deposits(address(this)), amount);
    }
}