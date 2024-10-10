// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Orderbook.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";

contract OrderbookTest is Test {
    Orderbook orderbook;
    TokenA tokenA;
    TokenB tokenB;
    address trader1 = address(0x1);
    address trader2 = address(0x2);

    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        orderbook = new Orderbook(IERC20(address(tokenA)), IERC20(address(tokenB)), 1); // Inicializar con una tarifa de 1%

        tokenA.transfer(trader1, 1000); // Asignar tokens A a trader1
        tokenB.transfer(trader2, 5000); // Asignar tokens B a trader2

        vm.startPrank(trader1);
        tokenA.approve(address(orderbook), type(uint256).max); // Aprobar Orderbook para trader1
        vm.stopPrank();

        vm.startPrank(trader2);
        tokenB.approve(address(orderbook), type(uint256).max); // Aprobar Orderbook para trader2
        vm.stopPrank();
    }

    function testPlaceOrder() public {
        vm.startPrank(trader2);
        orderbook.placeOrder(100, 50, true);
        vm.stopPrank();
        assertEq(orderbook.getBuyOrders().length, 1);
    }

    function testOrderMatching() public {
        vm.startPrank(trader2);
        orderbook.placeOrder(100, 50, true);
        vm.stopPrank();

        vm.startPrank(trader1);
        orderbook.placeOrder(100, 50, false);
        vm.stopPrank();

        assertEq(orderbook.getBuyOrders().length, 0);
        assertEq(orderbook.getSellOrders().length, 0);

        uint256 expectedTokenAForTrader2 = 100;
        uint256 expectedTokenBForTrader1 = 5000;

        assertEq(tokenA.balanceOf(trader2), expectedTokenAForTrader2);
        assertEq(tokenB.balanceOf(trader1), expectedTokenBForTrader1);
    }

    function testPartialOrderMatching() public {
        vm.startPrank(trader2);
        orderbook.placeOrder(100, 50, true);
        vm.stopPrank();

        vm.startPrank(trader1);
        orderbook.placeOrder(50, 50, false);
        vm.stopPrank();

        assertEq(orderbook.getBuyOrders().length, 1);
        assertEq(orderbook.getBuyOrders()[0].amount, 50);
        assertEq(orderbook.getSellOrders().length, 0);

        assertEq(tokenA.balanceOf(trader2), 50);
        assertEq(tokenB.balanceOf(trader1), 2500);
    }

    function testInsufficientBalanceReverts() public {
        vm.startPrank(trader1);
        vm.expectRevert("Insufficient balance to place sell order");
        orderbook.placeOrder(2000, 50, false);
        vm.stopPrank();
    }

    function testCancelOrder() public {
        vm.startPrank(trader2);
        orderbook.placeOrder(100, 50, true);
        assertEq(orderbook.getBuyOrders().length, 1);

        orderbook.cancelOrder(0, true);
        Orderbook.Order[] memory buyOrders = orderbook.getBuyOrders();
        assertEq(buyOrders.length, 1);
        assertFalse(buyOrders[0].isActive);
        vm.stopPrank();

        vm.startPrank(trader1);
        orderbook.placeOrder(100, 50, false);
        assertEq(orderbook.getSellOrders().length, 1);

        orderbook.cancelOrder(0, false);
        Orderbook.Order[] memory sellOrders = orderbook.getSellOrders();
        assertEq(sellOrders.length, 1);
        assertFalse(sellOrders[0].isActive);
        vm.stopPrank();
    }

    function testUnmatchedOrdersDueToPrice() public {
        vm.startPrank(trader2);
        orderbook.placeOrder(100, 40, true);
        vm.stopPrank();

        vm.startPrank(trader1);
        orderbook.placeOrder(100, 50, false);
        vm.stopPrank();

        assertEq(orderbook.getBuyOrders().length, 1);
        assertEq(orderbook.getSellOrders().length, 1);
    }
}
