import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploy() {

    // Contracts are deployed using the first signer/account by default
    const [owner, user1, user2, otherAccount] = await ethers.getSigners();

    const ERC20Token = await ethers.getContractFactory("PayToken")
    const payToken = await ERC20Token.connect(user2).deploy(10000)

    const KaiKongFactory = await ethers.getContractFactory("KaiKongsFactory");
    const factory = await KaiKongFactory.deploy();

    const marketplaceFactory = await ethers.getContractFactory("KaiKongsMarketplace");
    const marketplace = await marketplaceFactory.deploy(5000, owner.address, factory.address);

    await marketplace.addPayableToken(payToken.address)

    return { factory, marketplace, owner, user1, user2, payToken, otherAccount };
  }

  describe("Deployment", function () {
    it("Should list the token with id of 1", async function () {
      const { factory, marketplace, owner, user1, user2, payToken, otherAccount } = await loadFixture(deploy);
      // create collection of user1
      await (await factory.connect(user1).createCollection("KaiKongs", "KK", 1000, user1.address, 15, 10000, "ipfs://bafybeicc7qf4nu6scvwse7xt3g3uadcmf2t467qus75arezj3m57ei4qvq/")).wait()

      const nft = await factory.nfts(user1.address, 0)
      const nftContract = await ethers.getContractAt("KaiKongs", nft)
      await nftContract.connect(user1).mint(user1.address, 10) // mint 10 nfts to user1
      console.log('==============before list=============')
      expect(await nftContract.ownerOf(1)).to.equal(user1.address);
      expect(await nftContract.ownerOf(2)).to.equal(user1.address);
      
      await (await nftContract.connect(user1).setApprovalForAll(marketplace.address, true)).wait()
      await (await marketplace.connect(user1).createSell(nft, 1, payToken.address, 20, user1.address)).wait() //create sell of first nft of  user1
      console.log('==============after list=============')
      expect(await nftContract.ownerOf(1)).to.equal(marketplace.address);
      expect(await nftContract.ownerOf(2)).to.equal(user1.address);

      await (await payToken.approve(marketplace.address, 1000)).wait()
      await (await marketplace.connect(user2).buy(nft, 1, payToken.address, 20)).wait()
      console.log('==============after buy=============')
      expect(await nftContract.ownerOf(1)).to.equal(user2.address);
      expect(await nftContract.ownerOf(2)).to.equal(user1.address);
    });

    // it("Should set the right owner", async function () {
    //   const { lock, owner } = await loadFixture(deployOneYearLockFixture);

    //   expect(await lock.owner()).to.equal(owner.address);
    // });

    // it("Should receive and store the funds to lock", async function () {
    //   const { lock, lockedAmount } = await loadFixture(
    //     deployOneYearLockFixture
    //   );

    //   expect(await ethers.provider.getBalance(lock.address)).to.equal(
    //     lockedAmount
    //   );
    // });

    // it("Should fail if the unlockTime is not in the future", async function () {
    //   // We don't use the fixture here because we want a different deployment
    //   const latestTime = await time.latest();
    //   const Lock = await ethers.getContractFactory("Lock");
    //   await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
    //     "Unlock time should be in the future"
    //   );
    // });
  });

//   describe("Withdrawals", function () {
//     describe("Validations", function () {
//       it("Should revert with the right error if called too soon", async function () {
//         const { lock } = await loadFixture(deployOneYearLockFixture);

//         await expect(lock.withdraw()).to.be.revertedWith(
//           "You can't withdraw yet"
//         );
//       });

//       it("Should revert with the right error if called from another account", async function () {
//         const { lock, unlockTime, otherAccount } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         // We can increase the time in Hardhat Network
//         await time.increaseTo(unlockTime);

//         // We use lock.connect() to send a transaction from another account
//         await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
//           "You aren't the owner"
//         );
//       });

//       it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
//         const { lock, unlockTime } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         // Transactions are sent using the first signer by default
//         await time.increaseTo(unlockTime);

//         await expect(lock.withdraw()).not.to.be.reverted;
//       });
//     });

//     describe("Events", function () {
//       it("Should emit an event on withdrawals", async function () {
//         const { lock, unlockTime, lockedAmount } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         await time.increaseTo(unlockTime);

//         await expect(lock.withdraw())
//           .to.emit(lock, "Withdrawal")
//           .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
//       });
//     });

//     describe("Transfers", function () {
//       it("Should transfer the funds to the owner", async function () {
//         const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         await time.increaseTo(unlockTime);

//         await expect(lock.withdraw()).to.changeEtherBalances(
//           [owner, lock],
//           [lockedAmount, -lockedAmount]
//         );
//       });
//     });
//   });
});
