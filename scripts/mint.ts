import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  let nftaddress = "0xa16e02e87b7454126e5e10d957a927a7f5b5d2be";
  let marketAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  let nft = await ethers.getContractAt("KaiKongs", nftaddress);
  let market = await ethers.getContractAt("KaiKongsMarketplace", marketAddress);

  await (await nft.mint(owner.address, 10)).wait();

  await (await nft.setApprovalForAll(marketAddress, true)).wait();
  for (let i = 3; i < 14; i++) {
    await (
      await market.createSell(
        nftaddress,
        i,
        ethers.utils.parseEther(i.toString()),
        owner.address
      )
    ).wait();
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
