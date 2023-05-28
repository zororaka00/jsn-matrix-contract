import { ethers, upgrades } from "hardhat";

async function main() {
  let instance_busd = await (await ethers.getContractFactory("TokenExample")).deploy();
  await instance_busd.deployed();
  console.log(`Address BUSD Contract: ${instance_busd.address}`);

  let instance_shareowner = [];
  const ShareOwner = await ethers.getContractFactory("ShareOwnerV2");
  const addressOwner = ["0x75552A8202076e707F37cf6c5F0782BCA054a6F3", "0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35"];
  instance_shareowner[0] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[1] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[2] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[3] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[4] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[5] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[6] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[7] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[8] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[9] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[10] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  instance_shareowner[11] = await upgrades.deployProxy((ShareOwner), [addressOwner], { kind: 'uups' });
  let address_shareowner = await instance_shareowner.map((d: any) => d.address);
  console.log(`Address Share Owner Contract: ${address_shareowner}`);

  let instance_matrix = await upgrades.deployProxy((await ethers.getContractFactory("MatrixV2")),
  [instance_busd.address, address_shareowner, addressOwner], { kind: 'uups' });
  await instance_matrix.deployed();
  console.log(`Address Matrix Contract: ${instance_matrix.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
