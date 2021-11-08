const hre = require("hardhat");

async function main() {
  // Bob is the owner of Token contract and he wants to send some token amount to dave
  const testnetAccount = await hre.reef.getSignerByName("testnet_account");

  const testnetAddress = await testnetAccount.getAddress ();

  console.log ("Testnet address: " + testnetAddress);
  // const dave = await hre.reef.getSignerByName("dave");

  // Extracting user addresses
  // const bobAddress = await bob.getAddress();
  // const daveAddress = await dave.getAddress();

  // Token contract address
  const nftAddress = "0xA9b387cB35253A00c181A2D09BD7a2fc34Ac917D";

  // Retrieving Token contract from chain
  const nft = await hre.reef.getContractAt("ERC1155WithRoyalties", nftAddress, testnetAccount);

  // console.log (nft);

  const newNft = await nft.mint (testnetAddress, 1, 'randomshit', testnetAddress, 25);

  console.log (newNft);

  console.log (await nft.balanceOf (testnetAddress, 2));

  console.log (await nft.uri (1));

  // Let's see Dave's balance
  // let daveBalance = await token.balanceOf(daveAddress);
  // console.log(
  //   "Balance of to address before transfer:",
  //   await daveBalance.toString()
  // );

  // // Bob transfers 10000 tokens to Dave
  // await token.transfer(daveAddress, 10000);

  // // Let's once again check Dave's balance
  // daveBalance = await token.balanceOf(daveAddress);
  // console.log(
  //   "Balance of to address after transfer:",
  //   await daveBalance.toString()
  // );

  // // Bob's amount after transactions
  // const bobBalance = await token.balanceOf(bobAddress);
  // console.log(
  //   "Balance of from address after transfer:",
  //   await bobBalance.toString()
  // );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
