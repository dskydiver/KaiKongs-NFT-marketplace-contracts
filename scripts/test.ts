import { ethers } from "hardhat";

async function main() {
  const [owner, user1, user2] = await ethers.getSigners();

  let marketplaceAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  let factoryAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  let nftAddress = "0xa16E02E87b7454126E5E10d957A927A7F5B5d2be";
  let baseURI =
    "ipfs://bafybeicc7qf4nu6scvwse7xt3g3uadcmf2t467qus75arezj3m57ei4qvq/";
  const marketplace = await ethers.getContractAt(
    "KaiKongsMarketplace",
    marketplaceAddress
  );

  // await (
  //   await marketplace
  //     .connect(user1)
  //     .makeOffer(nftAddress, 3, ethers.utils.parseEther("1"), {
  //       value: ethers.utils.parseEther("1"),
  //     })
  // ).wait();
  // await (
  //   await marketplace
  //     .connect(user2)
  //     .makeOffer(nftAddress, 4, ethers.utils.parseEther("2"), {
  //       value: ethers.utils.parseEther("2"),
  //     })
  // ).wait();

  await (await marketplace.connect(user1).cancelOffer(nftAddress, 3)).wait();
  await (await marketplace.acceptOfferNFT(nftAddress, 4, user2.address)).wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
