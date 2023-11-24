import { ethers } from 'hardhat';

async function main() {

  if(!process.env.SEPOLIA_LINK_ADDRESS) { throw new Error('.env.SEPOLIA_LINK_ADDRESS not set')}
  
  if(!process.env.UPKEEP_ADDRESS) { throw new Error('.env.UPKEEP_ADDRESS not set')}

  const carbonLayer = await ethers.deployContract('CarbonLayer', [process.env.SEPOLIA_LINK_ADDRESS]);
  await carbonLayer.waitForDeployment();

  const carbonAssert = await ethers.deployContract('CarbonAssert', [carbonLayer.target]);
  await carbonAssert.waitForDeployment();

  const carbonQuery = await ethers.deployContract('CarbonQuery', [carbonLayer.target]);
  await carbonQuery.waitForDeployment();
  
  carbonLayer.setAutomation(process.env.UPKEEP_ADDRESS)

  console.log(`=============================================`);
  console.log(`CarbonLayer deployed to ${carbonLayer.target}`);
  console.log(`CarbonAssert deployed to ${carbonAssert.target}`);
  console.log(`CarbonQuery deployed to ${carbonQuery.target}`);
  console.log(`=============================================`);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
``