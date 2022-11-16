// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const { verify } = require("./verifySVCcontract.js");
async function main() {
  [back_end, fee_receipient] = await ethers.getSigners();
  // let nft1155;
  // const NFT_1155 = await ethers.getContractFactory("NFT_1155");
  // nft1155 = await NFT_1155.deploy("", back_end.address);
  // await nft1155.deployed();
  // console.log("Deploy nft1155 at:", nft1155.address);

  let collection;
  const Collection = await ethers.getContractFactory("collection");
  collection = await Collection.deploy(back_end.address);
  await collection.deployed();
  console.log("Deploy collection at:", collection.address);

  // let clonefactory;
  // const cloneFactory = await ethers.getContractFactory("cloneFactory");
  // clonefactory = await cloneFactory.deploy();
  // await clonefactory.deployed();
  // console.log("Deploy clonefactory at:", clonefactory.address);
  // let MKP;
  // const Marketplace = await ethers.getContractFactory("Marketplace");
  // MKP = await Marketplace.deploy(
  //   back_end.address,
  //   nft1155.address,
  //   fee_receipient.address,
  //   10,
  //   25
  // );
  // console.log("Deploy MKP at:", MKP.address);
  
  // let svc;
  // const SVCToken = await ethers.getContractFactory("SVCToken");
  // svc = await SVCToken.connect(back_end).deploy(
  //   "name",
  //   "symbol",
  //   ethers.utils.parseEther("10000.0")
  // );
  // await svc.deployed();
  // console.log("Deploy svc at:", svc.address);
  // await verify(svc.address, args);
  //await nft1155.connect(back_end).setMKPAddress(MKP.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
