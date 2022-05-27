const { utils } = require("ethers");

async function main() {
    const baseTokenURI = "ipfs://QmRhKMvuWoL9AyN97Zvucd4DwQ8CM49mwiSL5B7ipY5yKY/";

    // Get owner/deployer's wallet address
    const [owner] = await hre.ethers.getSigners();

    // Get contract that we want to deploy
    const contractFactory = await hre.ethers.getContractFactory("NFTCollectible");

    // Deploy contract with the correct constructor arguments
    const contract = await contractFactory.deploy(baseTokenURI);

    // Wait for this transaction to be mined
    await contract.deployed();

    // Get contract address
    console.log("Contract deployed to:", contract.address);
    

    // // Mint 3 NFTs by sending 0.1 matic
    // txn = await contract.mintNFTs(10, { value: utils.parseEther('0') });
    // await txn.wait()

    // // Get all token IDs of the owner
    // let tokens = await contract.tokensOfOwner(owner.address)
    // console.log("Owner has tokens: ", tokens);
    // console.log("WalletAddress: ", owner.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
