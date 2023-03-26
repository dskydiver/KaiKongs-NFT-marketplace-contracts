import { ethers } from "hardhat";

async function main() {
  const [owner, user1] = await ethers.getSigners();

  let marketplaceAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  let factoryAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  let nftAddress = "0xa16E02E87b7454126E5E10d957A927A7F5B5d2be";
  let baseURI =
    "ipfs://bafybeicc7qf4nu6scvwse7xt3g3uadcmf2t467qus75arezj3m57ei4qvq/";
  const marketplace = await ethers.getContractAt(
    "KaiKongsMarketplace",
    marketplaceAddress
  );

  const nft = await ethers.getContractAt("KaiKongs", nftAddress);

  await (await nft.approve(marketplaceAddress, 1)).wait();
  await (
    await marketplace.createSell(
      nftAddress,
      1,
      ethers.utils.parseEther("3"),
      owner.address
    )
  ).wait();

  await (
    await marketplace.connect(user1).buy(nftAddress, 1, {
      value: ethers.utils.parseEther("3"),
    })
  ).wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
