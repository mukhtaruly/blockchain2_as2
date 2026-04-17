// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IUniswapV2Router {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract ForkTest is Test {
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IERC20 usdc;
    IUniswapV2Router router;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/dSNDbyHWFlV_OXoHw9urK");

        usdc = IERC20(USDC);
        router = IUniswapV2Router(ROUTER);
    }

    function testReadUSDCSupply() public view {
        uint256 supply = usdc.totalSupply();
        assertGt(supply, 0);
    }

    function testSwapETHToUSDC() public {
        vm.deal(address(this), 1 ether);

        // ✅ ВАЖНО: объявление массива
        address [] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        uint beforeBalance = usdc.balanceOf(address(this));

        router.swapExactETHForTokens{value: 0.1 ether}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint afterBalance = usdc.balanceOf(address(this));

        assertGt(afterBalance, beforeBalance);
    }
}