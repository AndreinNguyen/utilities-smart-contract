require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");

require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "develop",
  networks: {
    hardhat: {},
    rinkeby: {
      url: process.env.RINKEBY_URL,
      accounts: [
        process.env.DEV_PRIVATE_KEY, process.env.FEE_PRIVATE_KEY
      ],
    },
    polygonMumbai: {
      url: process.env.MUMBAI_URL,
      accounts: [
        process.env.DEV_PRIVATE_KEY, process.env.FEE_PRIVATE_KEY
      ],
    },
    bscTestnet: {
      url: process.env.BSC_URL,
      

      accounts: [
        process.env.DEV_PRIVATE_KEY, process.env.FEE_PRIVATE_KEY
      ],
    },

    develop: {
      url:  process.env.LOCAL_URL,
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.com/
    apiKey: {
      bscTestnet: process.env.BSC_API_KEY,

      polygonMumbai: process.env.POLYGON_API_KEY,
    },
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 40000,
  },
};
