require("@nomiclabs/hardhat-waffle");

// The next line is part of the sample project, you don't need it in your
// project. It imports a Hardhat task definition, that can be used for
// testing the frontend.
require("./tasks/faucet");

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
  }
  // networks: {
  //   hardhat: {
  //   },
  //   kovan: {
  //     url: `https://kovan.infura.io/v3/${infuraId}`,
  //     accounts: [privateKey]
  //   },
  //   fantom: {
  //     url: "https://rpcapi.fantom.network",
  //     accounts: [privateKey],
  //   },
  //   "fantom-testnet": {
  //     url: "https://rpc.testnet.fantom.network",
  //     accounts: [privateKey],
  //   },
  // },
};

