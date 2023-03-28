import { ethers, upgrades } from "hardhat";

async function main() {
  const [owner, user1, user2] = await ethers.getSigners();
  let baseURI =
    "ipfs://bafybeicc7qf4nu6scvwse7xt3g3uadcmf2t467qus75arezj3m57ei4qvq/";
  const MarketplaceFactory = await ethers.getContractFactory(
    "KaiKongsMarketplace"
  );
  const KaiKongsF = await ethers.getContractFactory("KaiKongsFactory");

  const kaiKongsFactory = await KaiKongsF.deploy();
  await kaiKongsFactory.deployed();
  console.log("Kaikongsfactory is deployed to: ", kaiKongsFactory.address);

  const marketplace = await upgrades.deployProxy(MarketplaceFactory, [
    "10000",
    owner.address,
    kaiKongsFactory.address,
  ]);
  await marketplace.deployed();

  console.log("marketplace is deployed to: ", marketplace.address);

  await (
    await kaiKongsFactory.createCollection(
      "KaiKongs",
      "KK",
      10000,
      owner.address,
      ethers.utils.parseEther("1"),
      10000,
      baseURI
    )
  ).wait();

  let nftAddress = (await kaiKongsFactory.getUserCollections(owner.address))[0];
  console.log(nftAddress);

  let nft = await ethers.getContractAt("KaiKongs", nftAddress);

  await (await nft.mint(owner.address, 3)).wait();

  await (await nft.approve(marketplace.address, 1)).wait();
  await (await nft.approve(marketplace.address, 2)).wait();

  await (
    await marketplace.createSell(
      nftAddress,
      1,
      ethers.utils.parseEther("3"),
      owner.address
    )
  ).wait();
  await (
    await marketplace.createSell(
      nftAddress,
      2,
      ethers.utils.parseEther("4"),
      owner.address
    )
  ).wait();

  console.log("========================");
  // await (
  //   await marketplace
  //     .connect(user1)
  //     .buy(nftAddress, 1, { value: ethers.utils.parseEther("3") })
  // ).wait();
  // await (
  //   await marketplace
  //     .connect(user2)
  //     .buy(nftAddress, 2, { value: ethers.utils.parseEther("4") })
  // ).wait();

  await (
    await marketplace.connect(user1).bulkBuy([nftAddress, nftAddress], [1, 2], {
      value: ethers.utils.parseEther("7"),
    })
  ).wait();

  console.log(await nft.balanceOf(owner.address));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
