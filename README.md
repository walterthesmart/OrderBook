# OrderBook Smart Contract

## Overview

This repository contains a decentralized order book implementation written in Clarity for the Stacks blockchain. The smart contract enables secure, transparent peer-to-peer trading of assets with on-chain order matching and settlement.

## Features

- Limit orders: Place buy or sell orders at a specific price
- Market orders: Execute trades at the best available price
- Order cancellation: Users can cancel their open orders
- Efficient matching algorithm: Optimized for gas consumption
- Transparent and decentralized: All trades are settled on-chain

## Smart Contract Structure

The main contract file is `contracts/order-book.clar`. It implements the core functionality of the order book, including:

- Order placement
- Order matching
- Order cancellation
- Market price calculation

## Prerequisites

To interact with this smart contract, you'll need:

- [Clarinet](https://github.com/hirosystems/clarinet): A Clarity runtime packaged as a command-line tool
- [Stacks Wallet](https://www.hiro.so/wallet): To interact with the Stacks blockchain

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/walterthesmart/OrderBook.git
   cd OrderBook
   ```

2. Install Clarinet following the [official documentation](https://docs.hiro.so/smart-contracts/clarinet).

3. Initialize the Clarinet project (if not already done):
   ```
   clarinet init
   ```

4. Deploy the contract to the Stacks testnet or mainnet using Clarinet.

## Usage

### Placing an Order

To place a limit order, call the `place-limit-order` function with the following parameters:
- `side`: "buy" or "sell"
- `price`: The price per unit
- `amount`: The amount of the asset to trade

Example:
```clarity
(contract-call? .order-book place-limit-order "buy" u100000000 u5)
```

### Cancelling an Order

To cancel an existing order, use the `cancel-order` function with the order ID:

```clarity
(contract-call? .order-book cancel-order u1)
```

### Viewing the Order Book

To view the current state of the order book, you can call various read-only functions such as `get-buy-orders` and `get-sell-orders`.

## Testing

Run the included test suite using Clarinet:

```
clarinet test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This smart contract is provided as-is. Users should perform their own security audits before using it in a production environment.

## Contact

For questions or feedback, please open an issue on this GitHub repository.
