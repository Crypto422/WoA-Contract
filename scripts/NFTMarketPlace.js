const hre = require("hardhat");

async function main() {
  const NFTMarketPlace = await hre.ethers.getContractFactory("NFTMarketPlace");
  const marketPlace = await NFTMarketPlace.deploy();

  await marketPlace.deployed();

  console.log("NFTMarketPlace deployed to:", marketPlace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });