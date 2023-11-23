import { ethers } from 'hardhat';

async function main() {

  if(!process.env.SEPOLIA_LINK_ADDRESS) { throw new Error('.env.SEPOLIA_LINK_ADDRESS not set')}
  
  if(!process.env.UPKEEP_ADDRESS) { throw new Error('.env.UPKEEP_ADDRESS not set')}

  const carbonLayer = await ethers.deployContract('CarbonLayer', [process.env.SEPOLIA_LINK_ADDRESS]);
  await carbonLayer.waitForDeployment();

  const carbonAware = await ethers.deployContract('CarbonAware', [carbonLayer.target]);
  await carbonAware.waitForDeployment();
  
  carbonLayer.setAutomation(process.env.UPKEEP_ADDRESS)

  console.log(`=============================================`);
  console.log(`CarbonLayer deployed to ${carbonLayer.target}`);
  console.log(`CarbonAware deployed to ${carbonAware.target}`);
  console.log(`=============================================`);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
``