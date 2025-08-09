# Foundry Account Abstraction

[![CI](https://github.com/tohidul3417/foundry-account-abstraction/actions/workflows/test.yml/badge.svg)](https://github.com/tohidul3417/foundry-account-abstraction/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This project implements a smart contract wallet using **Account Abstraction (AA)**, with support for both **Ethereum (via ERC-4337)** and **zkSync (Native AA)**. It was developed using the [Foundry](https://github.com/foundry-rs/foundry) framework.

The primary goal is to demonstrate and explore the core concepts of account abstraction in a practical, hands-on manner. The repository contains two distinct smart contract accounts, each tailored to its respective blockchain environment, along with comprehensive tests and deployment scripts.

This repository was completed as a learning exercise for the **Advanced Foundry** course's *Account Abstraction* section, offered by Cyfrin Updraft.

-----

## System Architecture

The project's architecture is designed for multi-chain support, providing distinct implementations for Ethereum and zkSync. A central `HelperConfig` contract dynamically manages network-specific parameters.

### Ethereum (ERC-4337 Implementation)

  * `MinimalAccount.sol`: A simplified smart contract wallet compliant with `IAccount` from the ERC-4337 specification.
      * It can be owned and managed by an Externally Owned Account (EOA).
      * The `validateUserOp` function is used by the central `EntryPoint` contract to verify a user's operation (e.g., by checking a signature).
      * The `execute` function allows the owner (or the `EntryPoint` contract) to make arbitrary calls from the smart contract wallet.

### zkSync (Native AA Implementation)

  * `ZkMinimalAccount.sol`: A smart contract wallet built for zkSync's native account abstraction model.
      * It uses a different interface and validation logic than the Ethereum counterpart.
      * `validateTransaction` is the core function for authorizing transactions. It checks the transaction signature and increments the nonce.
      * `executeTransaction` is used to perform the actual call from the account.

### Configuration and Scripts

  * `HelperConfig.s.sol`: A crucial contract for multi-chain support. It detects the current chain ID and provides the correct network-specific addresses (like the `EntryPoint` for Ethereum or other relevant contracts) for both live networks and local Anvil testing.
  * `DeployMinimal.s.sol`: A script to deploy the Ethereum `MinimalAccount` contract and transfer ownership.
  * `SendPackedUserOp.s.sol`: A script that demonstrates how to create, sign, and send a `PackedUserOperation` to the `EntryPoint` contract on an Ethereum-compatible chain.

-----

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing.

### Prerequisites

  * [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  * [Foundry](https://getfoundry.sh/)

### Installation

1.  **Clone the repository** (including submodules):

    ```bash
    git clone --recurse-submodules https://github.com/tohidul3417/foundry-account-abstraction.git
    cd foundry-account-abstraction
    ```

2.  **Install dependencies**:
    This project uses Git submodules, which are initialized during the cloning process. You can update them if needed:

    ```bash
    git submodule update --init --recursive
    ```

3.  **Build the project**:

    ```bash
    forge build
    ```

4.  **Set up environment variables**:
    Create a file named `.env` in the root of the project. This file will hold your RPC URLs and other secrets.

    ```bash
    touch .env
    ```

    Add the following variables to your new `.env` file, replacing the placeholder values with your own:

    ```
    SEPOLIA_RPC_URL="YOUR_SEPOLIA_RPC_URL"
    ZKSYNC_SEPOLIA_RPC_URL="YOUR_ARBITRUM_SEPOLIA_RPC_URL"
    # See the Advanced Security section for managing private keys
    ```

-----

### ⚠️ Advanced Security: The Professional Workflow for Key Management

Storing a plain-text `PRIVATE_KEY` in a `.env` file is a significant security risk. If that file is ever accidentally committed to GitHub, shared, or compromised, any funds associated with that key will be stolen instantly.

The professional standard is to **never store a private key in plain text**. Instead, we use Foundry's built-in **keystore** functionality, which encrypts your key with a password you choose.

#### **Step 1: Create Your Encrypted Keystore**

This command generates a new private key and immediately encrypts it, saving it as a secure JSON file.

1.  **Run the creation command:**

    ```bash
    cast wallet new
    ```

2.  **Enter a strong password:**
    The terminal will prompt you to enter and then confirm a strong password. **This is the only thing that can unlock your key.** Store this password in a secure password manager (like 1Password or Bitwarden).

3.  **Secure the output:**
    The command will output your new wallet's **public address** and the **path** to the encrypted JSON file (usually in `~/.foundry/keystores/`).

      * Save the public address. You will need it to send funds to your new secure wallet.
      * Note the filename of the keystore file.

At this point, your private key exists only in its encrypted form. It is no longer in plain text on your machine.

#### **Step 2: Fund Your New Secure Wallet**

Use a faucet or another wallet to send some testnet ETH to the new **public address** you just generated.

#### **Step 3: Use Your Keystore Securely for Deployments**

Now, when you need to send a transaction (like deploying a contract), you will tell Foundry to use your encrypted keystore. Your private key is **never** passed through the command line or stored in a file.

1.  **Construct the command:**
    Use the `--keystore` flag to point to your encrypted file and the `--ask-pass` flag to tell Foundry to securely prompt you for your password.

2.  **Example Deployment Command:**

    ```bash
    # This command deploys the MinimalAccount on Sepolia
    forge script script/DeployMinimal.s.sol:DeployMinimal \
      --rpc-url $SEPOLIA_RPC_URL \
      --keystore ~/.foundry/keystores/UTC--2025-08-04T...--your-wallet-address.json \
      --ask-pass \
      --broadcast \
      --verify
    ```

3.  **Enter your password when prompted:**
    Foundry will pause and securely ask for the password you created in Step 1.

**The Atomic Security Insight:** When you run this command, Foundry reads the encrypted file, asks for your password in memory, uses it to decrypt the private key for the single purpose of signing the transaction, and then immediately discards the decrypted key. The private key never touches your shell history or any unencrypted files. This is a vastly more secure workflow.

-----

## Usage

### Testing

The project includes a comprehensive test suite for both unit and integration scenarios.

  * **Run all tests**:
    ```bash
    forge test -vvv
    ```
  * **Run tests for zkSync**:
    ```bash
    foundryup-zksync && forge test --zksync --system-mode=true && foundryup
    ```
  * **Check test coverage**:
    ```bash
    forge coverage
    ```

### Deployment

The `script/` directory contains Foundry scripts for deploying and interacting with the protocol on a live testnet. Refer to the scripts for detailed command examples and the **Advanced Security** section for the recommended deployment workflow.

  * `DeployMinimal.s.sol`: Deploys the core `MinimalAccount` contract.
  * `SendPackedUserOp.s.sol`: Creates and sends a `PackedUserOperation` to the `EntryPoint`.

-----

## ⚠️ Security Disclaimer

This project was built for educational purposes and has **not** been audited. Do not use in a production environment or with real funds. Always conduct a full, professional security audit before deploying any smart contracts.

-----

## License

This project is distributed under the MIT License. See `LICENSE` for more information.
