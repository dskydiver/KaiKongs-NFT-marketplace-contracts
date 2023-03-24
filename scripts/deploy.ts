import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  const MarketplaceFactory = await ethers.getContractFactory(
    "KaiKongsMarketplace"
  );
  const KaiKongsF = await ethers.getContractFactory("KaiKongsFactory");

  const kaiKongsFactory = await KaiKongsF.deploy();
  await kaiKongsFactory.deployed();
  console.log("Kaikongsfactory is deployed to: ", kaiKongsFactory.address);

  const marketplace = await MarketplaceFactory.deploy(
    "10000",
    owner.address,
    kaiKongsFactory.address
  );
  await marketplace.deployed();

  console.log("marketplace is deployed to: ", marketplace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
