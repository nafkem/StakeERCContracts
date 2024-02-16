import { ethers } from "hardhat";

async function main() {
    
  const MyToken = await ethers.deployContract("MyToken"); 
  await MyToken.waitForDeployment();
  
  const SaveERC20 = await ethers.deployContract("SaveERC20",[MyToken.target]); 
  await SaveERC20.waitForDeployment();

  console.log(
    `SaveERC20 contract deployed to ${SaveERC20.target, MyToken.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
