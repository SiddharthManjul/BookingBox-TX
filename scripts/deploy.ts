const { ethers } = require("hardhat");
const fs = require('fs');

const deployContract = async () => {
  let contract;
  const taxPercent = 5;
  const securityFeePercent = 2;

  try {
    contract = await ethers.deployContract("BookingBox", [taxPercent, securityFeePercent]);
    await contract.waitForDeployment();
    console.log("Contracts deployed successfully!");
    console.log(contract.target);
    
    return contract;
  } catch (error) {
    console.log("Error deploying contract: ", error);
    throw error;
  }
}

const saveContractAddress = async (contract: any) => {
  try {
    const address = JSON.stringify({
      BookingBoxContract: contract.target,
    }, null, 4)
  } catch (error) {
    console.log("Error saving contract address: ", error);
    throw error;
  }
}

async function main() {
  let contract;

  try {
    contract = await deployContract();
    await saveContractAddress(contract);
    console.log("Contract deployment completed successfully!");
  } catch (error) {
    console.log("Unhandled error: ", error);
    
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


// Deployed address: 0x2ffA26803A967155a32203dE3a937A89B0d75dF6