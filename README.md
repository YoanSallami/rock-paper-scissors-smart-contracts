# yankenpo-smart-contracts
Smart contracts for Yankenpo blockchain based game !

[![Node.js CI](https://github.com/doxa-games-studio/yankenpo-smart-contracts/actions/workflows/node.js.yml/badge.svg)](https://github.com/doxa-games-studio/yankenpo-smart-contracts/actions/workflows/node.js.yml)

# Install

```
git clone https://github.com/doxa-games-studio/yankenpo-smart-contracts.git
cd yankenpo-smart-contracts
yarn
```

# Run the tests

Run the tests with:
```
yarn test
```

# Run on local Ethereum node

Run the hardhat local Ethereum node with:
```
yarn node
```

In another shell:
```
yarn deploy --network localhost
```

# Connect to the local network with MetaMask

First, click on `Add Network` then, create a custom network with the following parameters:

* Network Name: `Hardhat`
* New RPC URL: `http://127.0.0.1:8545`
* Chain ID: `31337`
* Currency Symbol: `ETH`

To import a test account in metamask:
1. Go to `Import account`
2. Choose `Private key`
3. Paste the private key generated by the local node

# Resources

* [Solidity documentation](https://docs.soliditylang.org/en/v0.8.0/)
* [Hardhat documentation](https://hardhat.org/getting-started/)
* [Openzeppelin documentation](https://docs.openzeppelin.com/openzeppelin/)
* [MetaMask documentation](https://metamask.zendesk.com/hc/en-us)
