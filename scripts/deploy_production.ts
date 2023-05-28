import { ethers, upgrades } from "hardhat";

async function main() {
  const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
  const addressBUSD = "0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39";
  const addressWMATIC = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";
  const addressSwapRouterUniswap = "0xe592427a0aece92de3edee1f18e0157c05861564";

  let instance_shareowner = [];
  const ShareOwner = await ethers.getContractFactory("ShareOwner");
  const addressOwner = ["0x75552A8202076e707F37cf6c5F0782BCA054a6F3", "0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35"];
  instance_shareowner[0] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[1] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[2] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[3] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[4] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[5] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[6] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[7] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[8] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[9] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[10] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  instance_shareowner[11] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  await delay(5000);
  let address_shareowner = await instance_shareowner.map((d: any) => d.address);
  console.log(`Address Share Owner Contract: ${address_shareowner}`);

  let instance_matrix = await upgrades.deployProxy((await ethers.getContractFactory("MatrixV2")),
  [addressBUSD, address_shareowner, addressOwner], { kind: 'uups' });
  await instance_matrix.deployed();
  console.log(`Address Matrix Contract: ${instance_matrix.address}`);

  let instance_swap = await upgrades.deployProxy((await ethers.getContractFactory("SwapJSNV2")),
  [addressWMATIC, addressSwapRouterUniswap], { kind: 'uups' });
  await instance_swap.deployed();
  console.log(`Address Swap Contract: ${instance_swap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
