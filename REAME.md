# OrderBook Smart Contract

## Overview

This OrderBook smart contract, implemented in Clarity for the Stacks blockchain, provides a decentralized platform for managing and executing trades. It allows users to place buy and sell orders, cancel their orders, and includes an automated order matching mechanism.

## Features

- Place buy and sell orders
- Cancel existing orders
- Automatic order matching
- Persistent storage of order information

## Contract Structure

### Data Variables

- `order-counter`: Tracks the total number of orders placed

### Data Maps

- `orders`: Stores order details including:
  - Owner
  - Order type (buy/sell)
  - Amount
  - Price
  - Timestamp

### Public Functions

1. `place-order`: Create new buy or sell orders
2. `cancel-order`: Cancel existing orders
3. `match-orders`: Execute the order matching algorithm

## Function Details

### place-order

```clarity
(define-public (place-order (order-type (string-ascii 4)) (amount uint) (price uint))
```

Places a new order in the order book.

- Parameters:
  - `order-type`: "buy" or "sell"
  - `amount`: Quantity to trade
  - `price`: Price per unit
- Returns: The new order ID

### cancel-order

```clarity
(define-public (cancel-order (order-id uint))
```

Cancels an existing order.

- Parameters:
  - `order-id`: ID of the order to cancel
- Returns: Success (true) or error code

### match-orders

```clarity
(define-public (match-orders))
```

Executes the order matching algorithm to process trades.

- Returns: Success (true)

## Usage

1. Deploy the contract to the Stacks blockchain.
2. Users can interact with the contract by calling its public functions:
   - To place an order: `(contract-call? .orderbook place-order "buy" u100 u50000)`
   - To cancel an order: `(contract-call? .orderbook cancel-order u1)`
   - To execute order matching: `(contract-call? .orderbook match-orders)`

## Security Considerations

- Only order owners can cancel their orders
- Uses block timestamp for order creation time
- Note: This contract is a basic implementation and may need additional security audits before production use

## Limitations and Future Improvements

- The current `match-orders` function may be inefficient for large order books
- No partial order filling implemented
- Lacks integration with actual token transfers
- Could benefit from additional order types and advanced trading features

## Development and Testing

To set up the development environment:

1. Install the [Clarinet](https://github.com/hirosystems/clarinet) development tool.
2. Clone this repository.
3. Run `clarinet console` to interact with the contract.

Testing:
- Unit tests: Run `clarinet test` to execute the test suite.
- Manual testing: Use the Clarinet console to call contract functions and verify behavior.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your proposed changes.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## License

[Specify your license here, e.g., MIT License]

## Contact

Nwaugo Walter - [nwaugowalter@gmail.com]

Project Link: [https://github.com/walterthesmart/orderbook](https://github.com/walterthesmart/orderbook)

## Acknowledgments

- Stacks blockchain documentation
- Clarity language reference

---