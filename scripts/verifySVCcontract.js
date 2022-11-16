const { run } = require('hardhat');

async function verify(contractAddress, args) {
    try {
      await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
      contract: "contracts/SVC.sol:SVCToken"
      });
    } catch (error) {
      console.error(error)
    }
  }
  
  module.exports = async () => {
    verify
  }