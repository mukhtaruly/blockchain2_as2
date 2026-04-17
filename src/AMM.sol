// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MyToken.sol";
import "./LPToken.sol";

contract AMM {
    MyToken public tokenA;
    MyToken public tokenB;
    LPToken public lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = MyToken(_tokenA);
        tokenB = MyToken(_tokenB);
        lpToken = new LPToken();
    }

    function addLiquidity(uint256 amountA, uint256 amountB) public {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 liquidity;

        if (lpToken.totalSupply() == 0) {
            liquidity = amountA;
        } else {
            liquidity = (amountA * lpToken.totalSupply()) / reserveA;
        }

        reserveA += amountA;
        reserveB += amountB;

        lpToken.mint(msg.sender, liquidity);
    }

    function removeLiquidity(uint256 liquidity) public {
        uint256 totalSupply = lpToken.totalSupply();

        uint256 amountA = (liquidity * reserveA) / totalSupply;
        uint256 amountB = (liquidity * reserveB) / totalSupply;

        lpToken.burn(msg.sender, liquidity);

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
    }

    function swap(address tokenIn, uint256 amountIn) public {
        require(amountIn > 0, "Invalid amount");

        bool isTokenA = tokenIn == address(tokenA);

        (MyToken tokenInput, MyToken tokenOutput, uint256 reserveIn, uint256 reserveOut) =
            isTokenA
                ? (tokenA, tokenB, reserveA, reserveB)
                : (tokenB, tokenA, reserveB, reserveA);

        // 🔹 сначала переводим токены
        tokenInput.transferFrom(msg.sender, address(this), amountIn);

        // 🔹 считаем output
        uint256 amountInWithFee = (amountIn * 997) / 1000;

        uint256 amountOut =
            (amountInWithFee * reserveOut) /
            (reserveIn + amountInWithFee);

        require(amountOut <= reserveOut, "Not enough liquidity");

        // 🔹 обновляем резервы
        if (isTokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        // 🔹 отправляем токены ПОСЛЕ обновления
        tokenOutput.transfer(msg.sender, amountOut);
    }
}