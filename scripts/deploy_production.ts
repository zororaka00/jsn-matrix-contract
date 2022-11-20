import { ethers } from "hardhat";

async function main() {
  const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
  const addressBUSD = "0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39";

  let instance_shareowner = [];
  const ShareOwner = await ethers.getContractFactory("ShareOwner");
  instance_shareowner[0] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[1] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[2] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[3] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[4] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[5] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[6] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[7] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[8] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[9] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[10] = await ShareOwner.deploy();
  await delay(5000);
  instance_shareowner[11] = await ShareOwner.deploy();
  await delay(5000);
  let address_shareowner = await instance_shareowner.map((d: any) => d.address);
  console.log(`Address Share Owner Contract: ${address_shareowner}`);

  let instance_matrix = await (await ethers.getContractFactory("Matrix")).deploy(addressBUSD, address_shareowner);
  await instance_matrix.deployed();
  console.log(`Address Matrix Contract: ${instance_matrix.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
