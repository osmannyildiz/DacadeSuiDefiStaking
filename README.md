# Basic Staking Contract 💰

This contract allows you to deposit Sui and receive MNT as a reward.
DeepBook logic is implemented in this package.

## Features

- Account module is responsible for creating account and other operations related to their operations.
- Admin module is responsible for the pool's interest. (Currently disabled)
- The MNT module represents the reward token.
- The Reward module is responsible for the calculating rewards amount for users.
- The staking module is responsible for all operations related to users.

## Build

```bash
sui move build
````

## Test Locally

```bash
sui move test
````
