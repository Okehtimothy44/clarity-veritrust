# VeriTrust

A blockchain-based solution for product authenticity certification and verification. This smart contract allows manufacturers to register products with unique identifiers and certification details, while enabling consumers to verify product authenticity.

## Features

- Product registration by authorized manufacturers
- Product certification with detailed metadata
- Public verification of product authenticity
- Transfer of product ownership
- Manufacturer authorization management
- Complete ownership history tracking for each product
- Historical transfer records with timestamps

## Getting Started

1. Clone the repository
2. Install Clarinet
3. Run tests using `clarinet test`

## Usage

Manufacturers can register products by calling the `register-product` function with a unique product ID and certification details. Consumers can verify product authenticity using the `verify-product` function.

### Ownership History

The contract now maintains a complete history of ownership transfers for each product. This feature enables:

- Tracking the complete chain of ownership from manufacturer to current owner
- Timestamp records for each transfer
- Up to 50 most recent ownership transfers stored per product
- Public access to ownership history through the `get-ownership-history` function

This enhancement provides greater transparency and traceability for product authenticity verification.
