require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

require('dotenv').config();

const {
    PRIVATE_KEY,
    MOONRIVER_API_URL,
    MOONRIVER_API,
    ETH_API_URL,
    RINKEBY_API_URL,
    ETHSCAN_API,
    BSC_TEST_API_URL,
    BSC_API_URL,
    BSCSCAN_API,
} = process.env;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        version: "0.8.4",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        mainnet: {
            url: ETH_API_URL,
            accounts: [PRIVATE_KEY],
        },
        moonriver: {
            url: MOONRIVER_API_URL,
            accounts: [PRIVATE_KEY],
        },
        binance: {
            url: BSC_API_URL,
            accounts: [PRIVATE_KEY],
        },
        binancetest: {
            url: BSC_TEST_API_URL,
            accounts: [PRIVATE_KEY],
        },
        polygon: {
            url: POLYGON_API_URL,
            accounts: [PRIVATE_KEY],
        },
        polygontest: {
            url: POLYGON_TEST_API_URL,
            accounts: [PRIVATE_KEY],
        },
    },
    etherscan: {
        apiKey: ETH_API_URL
    },
};