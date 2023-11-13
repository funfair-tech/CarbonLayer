import { ethers } from 'hardhat';

async function main() {
  const name = 'CarbonLayerClient';

  const contract = await ethers.deployContract(name, [process.env.SEPOLIA_LINK_ADDRESS]);

  await contract.waitForDeployment();

  console.log(`${name} deployed to ${contract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
