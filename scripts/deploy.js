const fs = require('fs');

// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is avaialble in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const CashPrinter = await ethers.getContractFactory("CashPrinter");
  const cashPrinter = await CashPrinter.deploy(BigInt(20000000 * 10 ** 18));
  await cashPrinter.deployed();

  console.log("CashPrinter token address:", cashPrinter.address);

  const CashPrinterStaking = await ethers.getContractFactory("CashPrinterStaking");
  const cashPrinterStaking = await CashPrinterStaking.deploy();
  await cashPrinterStaking.deployed();

  console.log("CashPrinterStaking address:", cashPrinterStaking.address);

  const CashPad = await ethers.getContractFactory("CashPad");
  const cashPad = await CashPad.deploy(cashPrinter.address, cashPrinterStaking.address);
  await cashPad.deployed();

  console.log("CashPad address:", cashPad.address);

  // We also save the contract's artifacts and address in the frontend directory
  // saveFrontendFiles(token);

  // save deployed address in config file
  let config = `
  export const cashPrinter = "${cashPrinter.address}"
  export const cashPrinterStaking = "${cashPrinterStaking.address}"
  export const cashPad = "${cashPad.address}"
  `

  let data = JSON.stringify(config);
  fs.writeFileSync('config.js', JSON.parse(data));
}

// function saveFrontendFiles(token) {
//   const fs = require("fs");
//   const contractsDir = __dirname + "/../frontend/src/contracts";

//   if (!fs.existsSync(contractsDir)) {
//     fs.mkdirSync(contractsDir);
//   }

//   fs.writeFileSync(
//     contractsDir + "/contract-address.json",
//     JSON.stringify({ Token: token.address }, undefined, 2)
//   );

//   const TokenArtifact = artifacts.readArtifactSync("HHToken");

//   fs.writeFileSync(
//     contractsDir + "/HHToken.json",
//     JSON.stringify(TokenArtifact, null, 2)
//   );
// }

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
