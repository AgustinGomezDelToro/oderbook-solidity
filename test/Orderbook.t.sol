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
        vm.startPrank(trader2); // Usamos trader2 para colocar una orden de compra
        orderbook.placeOrder(100, 50, true); // Colocar una orden de compra
        vm.stopPrank();
        assertEq(orderbook.getBuyOrders().length, 1); // Verificar que la orden fue colocada
    }

    function testOrderMatching() public {
        // Trader2 coloca una orden de compra usando tokenB
        vm.startPrank(trader2);
        orderbook.placeOrder(100, 50, true); // Colocar una orden de compra con tokenB
        vm.stopPrank();

        // Trader1 coloca una orden de venta usando tokenA
        vm.startPrank(trader1);
        orderbook.placeOrder(100, 50, false); // Colocar una orden de venta con tokenA
        vm.stopPrank();

        // Verificar que las órdenes se hayan emparejado
        assertEq(orderbook.getBuyOrders().length, 0, "All buy orders should be matched");
        assertEq(orderbook.getSellOrders().length, 0, "All sell orders should be matched");

        // Verificar los balances después del emparejamiento
        uint256 expectedTokenAForTrader2 = 100; // Trader2 debería recibir 100 tokenA
        uint256 expectedTokenBForTrader1 = 5000; // Trader1 debería recibir 5000 tokenB

        assertEq(tokenA.balanceOf(trader2), expectedTokenAForTrader2, "Trader2 should receive 100 tokenA");
        assertEq(tokenB.balanceOf(trader1), expectedTokenBForTrader1, "Trader1 should receive 5000 tokenB");
    }

    function testPartialOrderMatching() public {
        // Trader2 coloca una orden de compra con tokenB
        vm.startPrank(trader2);
        orderbook.placeOrder(100, 50, true); // Colocar una orden de compra
        vm.stopPrank();

        // Trader1 coloca una orden de venta por una cantidad menor
        vm.startPrank(trader1);
        orderbook.placeOrder(50, 50, false); // Colocar una orden de venta por 50
        vm.stopPrank();

        // Verificar que la orden de compra sigue activa, pero ha sido parcialmente emparejada
        assertEq(orderbook.getBuyOrders().length, 1, "Buy order should still be active");
        assertEq(orderbook.getBuyOrders()[0].amount, 50, "50 tokenB should remain for buying");
        assertEq(orderbook.getSellOrders().length, 0, "Sell order should be fully matched");

        // Verificar los balances después del emparejamiento parcial
        assertEq(tokenA.balanceOf(trader2), 50, "Trader2 should receive 50 tokenA");
        assertEq(tokenB.balanceOf(trader1), 2500, "Trader1 should receive 2500 tokenB");
    }

    function testInsufficientBalanceReverts() public {
        // Intentar que trader1 coloque una orden de venta sin suficiente balance de tokenA
        vm.startPrank(trader1);
        vm.expectRevert("Insufficient balance to place sell order");
        orderbook.placeOrder(2000, 50, false); // Intentar vender más de lo que posee
        vm.stopPrank();
    }
}