# Sqwid Core

The smart contracts of Sqwid Marketplace

Addresses on testnet:
```sh
COLLECTIBLE_CONTRACT_ADDRESS 0x192A6B3AA5A860F110A2479C32C29f790b21163b
MARKETPLACE_CONTRACT_ADDRESS 0xccc5309F6E92956970000d385D817438bbF7CeA9
UTILITY_CONTRACT_ADDRESS 0xc857bb5C1D062c465a1B3Cf8af19635cC3B8e1Bc
```

## Compiling

```
$ yarn hardhat compile
```

## Deploying

```
$ yarn deploy:erc1155
$ yarn deploy:marketplace
$ yarn deploy:utility
```


## Installing

Install dependencies with `yarn`.


## Running

Define your Reef chain URL in `hardhat.config.js` (by default `ws://127.0.0.1:9944`):

```
module.exports = {
  solidity: "0.7.3",
  defaultNetwork: "reef",
  networks: {
    reef: {
      url: "ws://127.0.0.1:9944",
    },
    reef_testnet: {
      url: "wss://rpc-testnet.reefscan.com/ws",
      seeds: {
        testnet_account: "<MNEMONIC_SEED>",
      },
    },
    reef_mainnet: {
      url: "wss://rpc.reefscan.com/ws",
      seeds: {
        mainnet_account: "<MNEMONIC_SEED>",
      },
    },
  },
};
```

Change `<MNEMONIC_SEED>` to your account seed for the corresponding network. Remove the `seeds` dictionary for the unneeded networks. You can have multiple accounts by listing them in dictionary with your custom name:

```
seeds: {
	account1: "<MNEMONIC_SEED1>",
	account2: "<MNEMONIC_SEED2>",
	...
},
```

In JS script you can select the account with:
```
const reef = await hre.reef.getSignerByName("account1");
```
where `account1` is the key of the item in the `seeds` dictionary.

If you get the following error:
```
Invalid Transaction: Inability to pay some fees , e.g. account balance too low
```

it is most likely because the accounts defined in the `hardhat.config.js` and JS script do not match.


## Scripts

See `scripts/` folder for example scripts, e.g. to deploy flipper run:

```
npx hardhat run scripts/flipper/deploy.js 
```

After the contract is deployed, you can interact with it using the `flip.js` script:

```
npx hardhat run scripts/flipper/flip.js 
```

make sure the `flipperAddress` corresponds to the deployed address.

## Deploying on testnet
The above commands will deploy on development (local) network by default. To deploy on testnet, use the `--network` flag:

```
npx hardhat run scripts/flipper/deploy.js --network reef_testnet 
```

To get initial REEF tokens on the testnet, visit [dev Matrix chat](https://app.element.io/#/room/#reef:matrix.org) and use the following command:
```
!drip REEF_ADDRESS
```
