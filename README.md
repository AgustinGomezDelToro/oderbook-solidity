# Projet Orderbook

## Description
Ce projet est un smart contract Solidity qui simule un orderbook pour échanger deux tokens ERC20. Les utilisateurs peuvent placer des ordres d'achat et de vente, et le smart contract se charge d'apparier les ordres correspondants.

## Prérequis
- Foundry (pour compiler et exécuter les tests)

## Installation

1. Clonez ce dépôt :
   ```bash
   git clone https://github.com/AgustinGomezDelToro/oderbook-solidity

2. Installez Foundry en suivant la documentation officielle : https://book.getfoundry.sh/getting-started/installation.html

Installez les dépendances si nécessaire :
```bash
    forge install
```

### Pour exécuter simplement les tests :

``` bash
forge coverage
```

## Fonctionnalités principales du contrat

- `placeOrder(uint256 amount, uint256 price, bool isBuyOrder)` : permet à un utilisateur de placer un ordre d'achat ou de vente.
- `matchOrders()` : fonction interne qui apparie les ordres d'achat et de vente disponibles.
- `cancelOrder(uint256 index, bool isBuyOrder)` : permet à un utilisateur d'annuler son ordre en fonction de son index.
- `getBuyOrders()` : retourne la liste des ordres d'achat actifs.
- `getSellOrders()` : retourne la liste des ordres de vente actifs.

## Structure du projet

- `src/Orderbook.sol` : contient le smart contract principal de l'orderbook.
- `src/TokenA.sol` et `src/TokenB.sol` : contrats simples ERC20 pour les tests.
- `test/Orderbook.t.sol` : tests unitaires du smart contract Orderbook.

## Explication des tests

Les tests unitaires vérifient plusieurs scénarios importants pour l'orderbook :

- `testPlaceOrder()` : Vérifie si un ordre d'achat est bien placé dans le carnet d'ordres.
- `testOrderMatching()` : Vérifie si les ordres d'achat et de vente se correspondent correctement et que les jetons sont échangés.
- `testPartialOrderMatching()` : Vérifie si une correspondance partielle est effectuée, et si le reste de l'ordre est maintenu actif.
- `testInsufficientBalanceReverts()` : Vérifie que l'exécution échoue si l'utilisateur n'a pas assez de fonds pour passer un ordre.
- `testCancelOrder()` : Vérifie qu'un utilisateur peut annuler un ordre d'achat ou de vente, et que celui-ci devient inactif.
- `testUnmatchedOrdersDueToPrice()` : Vérifie que les ordres ne sont pas appariés lorsque les prix ne correspondent pas.


