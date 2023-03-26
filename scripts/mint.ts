import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  let nftaddress = "0xa16e02e87b7454126e5e10d957a927a7f5b5d2be";
  let nft = await ethers.getContractAt("KaiKongs", nftaddress);

  await (
    await nft.mint(owner.address, 1, { value: ethers.utils.parseEther("1") })
  ).wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
