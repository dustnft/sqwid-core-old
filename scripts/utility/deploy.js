const hre = require("hardhat");

// We will deploy Token contract with Bob
// It is going to have the pool of 1000000 tokens
async function main() {
  // define your testnet_account in hardhat.config.js
  const testnetAccount = await hre.reef.getSignerByName("testnet_account");
  await testnetAccount.claimDefaultAccount();

  // const testnetAddress = await testnetAccount.getAddress ();

  const Utility = await hre.reef.getContractFactory ("SqwidMarketUtility", testnetAccount);

  const utility = await Utility.deploy ();

  console.log("Deploy done");
  console.log({
    utility: utility.address,
  });
  // console.log({
  //   name: await nft.name (),
  //   initialBalance: await nft.totalSupply().toString(),
  // });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
