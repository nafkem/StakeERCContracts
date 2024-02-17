import { ethers } from "hardhat";

async function main() {
    
  const MyToken = await ethers.deployContract("MyToken"); 
  await MyToken.waitForDeployment();
  console.log(`MyToken  deployed to ${MyToken.target}`);

  const StakeERC20 = await ethers.deployContract("StakeERC20 "); 
  await StakeERC20.waitForDeployment();

  console.log(
    `StakeERC20 contract deployed to ${StakeERC20.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
