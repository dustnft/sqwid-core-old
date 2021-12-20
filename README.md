# Sqwid Core

The smart contracts of Sqwid Marketplace

Addresses on testnet:
```sh
COLLECTIBLE_CONTRACT_ADDRESS 0xcBfC344bEefED6FEae98F0e2FF4af9580f601C34
MARKETPLACE_CONTRACT_ADDRESS 0x64c6855Ad6DFB9b9B6f700CfF231066398B46CA6
UTILITY_CONTRACT_ADDRESS 0x5Ba166aC0F513ec08F35CfD661760Db4928b815B
WRAPPER_CONTRACT_ADDRESS 0x304377e6c790347B978B6E496829011e43E43Aa2
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
$ yarn deploy:wrapper
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
