require('hardhat-deploy');
require('dotenv').config()
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: {
    version: "0.8.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  networks:{
    hardhat: {},
    fantom:{
      url: "https://rpc.ftm.tools/",
      chainId:250,
      accounts: [process.env.PRIVKEY]
    }
  },
  namedAccounts: {
    deployer:{
      default:0
    }
  }
};
