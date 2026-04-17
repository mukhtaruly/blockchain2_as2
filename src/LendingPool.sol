// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyToken.sol";

contract LendingPool {
    MyToken public token;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrows;

    uint256 public constant LTV = 75; // 75%

    constructor(address _token) {
        token = MyToken(_token);
    }

    // ✅ deposit
    function deposit(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
    }

    // ✅ borrow
    function borrow(uint256 amount) public {
        uint256 maxBorrow = (deposits[msg.sender] * LTV) / 100;

        require(borrows[msg.sender] + amount <= maxBorrow, "Exceeds LTV");

        borrows[msg.sender] += amount;
        token.transfer(msg.sender, amount);
    }

    // ✅ repay
    function repay(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), amount);
        borrows[msg.sender] -= amount;
    }

    // ✅ withdraw
    function withdraw(uint256 amount) public {
        require(deposits[msg.sender] >= amount, "Not enough deposit");

        uint256 remaining = deposits[msg.sender] - amount;
        uint256 maxBorrow = (remaining * LTV) / 100;

        require(borrows[msg.sender] <= maxBorrow, "Health factor too low");

        deposits[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    // ✅ liquidate
    function liquidate(address user) public {
        uint256 maxBorrow = (deposits[user] * LTV) / 100;

        require(borrows[user] >= maxBorrow, "Healthy");

        uint256 collateral = deposits[user];

        deposits[user] = 0;
        borrows[user] = 0;

        token.transfer(msg.sender, collateral);
    }
}