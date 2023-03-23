import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  let marketplaceAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  const marketplace = await ethers.getContractAt(
    "KaiKongsMarketplace",
    marketplaceAddress
  );

  let c = await marketplace.getPayableTokens();
  console.log(c);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
