require("@reef-defi/hardhat-reef");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await hre.reef.getSigners();

  for (const account of accounts) {
    console.log(await account.getAddress ());
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        optimizer: {
          enabled: true,
          runs: 200
        }
      },
      {
        version: "0.7.3",
      }
    ]
  },
  defaultNetwork: "reef",
  networks: {
    reef: {
      url: "ws://127.0.0.1:9944",
      seeds: {
        testnet_account: "<MNEMONIC_SEED>",
      },
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
