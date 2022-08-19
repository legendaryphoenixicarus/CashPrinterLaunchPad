require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

const privateKey = process.env.PRIVATE_KEY;
const infuraId = process.env.INFURA_ID;
const etherscanAPI = process.env.ETHERSCAN_API;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  defaultNetwork: "hardhat",
  settings: {
    optimizer: {
      runs: 200,
      enabled: true
    }
  },
  networks: {
    hardhat: {
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${infuraId}`,
      accounts: [privateKey]
    },
    fantom: {
      url: "https://rpcapi.fantom.network",
      accounts: [privateKey],
    },
    "fantom-testnet": {
      url: "https://rpc.testnet.fantom.network",
      accounts: [privateKey],
    },
    /* Binance Smart Chain */
    bscMain:{
      url:"https://bsc-dataseed.binance.org/",
      accounts: [privateKey]
    },
    bscTest:{
      url:"https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: [privateKey]
    },
    "dogechain": {
      url: "https://rpc01-sg.dogechain.dog",
      accounts: [privateKey],
    },
    "dogechain-testnet": {
      url: "https://rpc-testnet.dogechain.dog/",
      accounts: [privateKey],
    }
  },
  etherscan: {
    apiKey: etherscanAPI
  }
};

