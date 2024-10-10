// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Orderbook {
    struct Order {
        address trader;
        uint256 amount;
        uint256 price;
        bool isBuyOrder; // true = buy, false = sell
        bool isActive; // for cancellation
    }

    Order[] public buyOrders;
    Order[] public sellOrders;
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public transactionFee;

    event OrderPlaced(address trader, uint256 amount, uint256 price, bool isBuyOrder);
    event OrderCancelled(address trader, uint256 index);
    event OrderMatched(address buyer, address seller, uint256 amount, uint256 price);

    constructor(IERC20 _tokenA, IERC20 _tokenB, uint256 _transactionFee) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        transactionFee = _transactionFee;
    }

    function placeOrder(uint256 amount, uint256 price, bool isBuyOrder) external {
        if (isBuyOrder) {
            require(tokenB.balanceOf(msg.sender) >= amount * price, "Insufficient balance to place buy order");
            buyOrders.push(Order(msg.sender, amount, price, true, true));
            matchOrders();
        } else {
            require(tokenA.balanceOf(msg.sender) >= amount, "Insufficient balance to place sell order");
            sellOrders.push(Order(msg.sender, amount, price, false, true));
            matchOrders();
        }
        emit OrderPlaced(msg.sender, amount, price, isBuyOrder);
    }

    function matchOrders() internal {
        for (uint256 i = 0; i < buyOrders.length; i++) {
            if (!buyOrders[i].isActive) continue;

            for (uint256 j = 0; j < sellOrders.length; j++) {
                if (!sellOrders[j].isActive) continue;

                if (buyOrders[i].price >= sellOrders[j].price) {
                    uint256 amountToTrade = buyOrders[i].amount < sellOrders[j].amount ? buyOrders[i].amount : sellOrders[j].amount;
                    uint256 totalCostInTokenB = amountToTrade * sellOrders[j].price;

                    require(tokenB.transferFrom(buyOrders[i].trader, sellOrders[j].trader, totalCostInTokenB), "Buy transfer failed");
                    require(tokenA.transferFrom(sellOrders[j].trader, buyOrders[i].trader, amountToTrade), "Sell transfer failed");

                    buyOrders[i].amount -= amountToTrade;
                    sellOrders[j].amount -= amountToTrade;

                    emit OrderMatched(buyOrders[i].trader, sellOrders[j].trader, amountToTrade, sellOrders[j].price);

                    if (buyOrders[i].amount == 0) {
                        buyOrders[i].isActive = false;
                    }
                    if (sellOrders[j].amount == 0) {
                        sellOrders[j].isActive = false;
                    }

                    if (buyOrders[i].amount == 0) break;
                }
            }
        }

        _cleanInactiveOrders();
    }

    function _cleanInactiveOrders() internal {
        for (uint256 i = 0; i < buyOrders.length; i++) {
            if (!buyOrders[i].isActive) {
                _removeBuyOrder(i);
            }
        }

        for (uint256 j = 0; j < sellOrders.length; j++) {
            if (!sellOrders[j].isActive) {
                _removeSellOrder(j);
            }
        }
    }

    function _removeBuyOrder(uint256 index) internal {
        for (uint256 i = index; i < buyOrders.length - 1; i++) {
            buyOrders[i] = buyOrders[i + 1];
        }
        buyOrders.pop();
    }

    function _removeSellOrder(uint256 index) internal {
        for (uint256 i = index; i < sellOrders.length - 1; i++) {
            sellOrders[i] = sellOrders[i + 1];
        }
        sellOrders.pop();
    }

    function cancelOrder(uint256 index, bool isBuyOrder) external {
        if (isBuyOrder) {
            require(index < buyOrders.length, "Invalid order index");
            require(buyOrders[index].trader == msg.sender, "Not your order");
            buyOrders[index].isActive = false;
        } else {
            require(index < sellOrders.length, "Invalid order index");
            require(sellOrders[index].trader == msg.sender, "Not your order");
            sellOrders[index].isActive = false;
        }
        emit OrderCancelled(msg.sender, index);
    }

    function getBuyOrders() external view returns (Order[] memory) {
        return buyOrders;
    }

    function getSellOrders() external view returns (Order[] memory) {
        return sellOrders;
    }
}
