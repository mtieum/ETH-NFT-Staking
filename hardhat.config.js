require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades")
require("dotenv").config();

module.exports = {
  solidity: "0.8.13",
  networks: {
     hardhat: {},
     goerli: {
       url: process.env.REACT_APP_API_URL_GOERLI_INFURA,
       accounts: ['0x' + process.env.REACT_APP_PRIVATE_KEY_GOERLI],
       allowUnlimitedContractSize: true,
       gas: 2700000,
       gasPrice: 40000000000,
       timeout: 0
     },
    //  sepolia: {
    //    url: process.env.REACT_APP_API_URL_SEPOLIA_INFURA,
    //    accounts: ['0x' + process.env.REACT_APP_PRIVATE_KEY_SEPOLIA],
    //    allowUnlimitedContractSize: true,
    //    gas: 2100000,//21
    //    gasPrice: 2000000000,//80
    //  },
     mainnet: {
       url: process.env.REACT_APP_API_URL_MAINNET,
       accounts: [process.env.REACT_APP_PRIVATE_KEY_MAINNET],
       gas: 3500000,
       gasPrice: 35000000000
     }
  },
  paths: {
    artifacts: "./src/backend/artifacts",
    sources: "./src/backend/contracts",
    cache: "./src/backend/cache",
    tests: "./src/backend/test"
  },
  etherscan: {
    apiKey: process.env.REACT_APP_ETHERSCAN_API_KEY
    // apiKey: process.env.REACT_APP_POLYGONSCAN_API_KEY
  }
};
