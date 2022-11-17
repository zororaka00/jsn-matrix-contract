import { expect } from "chai";
import { ethers } from "hardhat";

describe("MLM", () => {
  let instance_busd: any;
  let instance_matrix: any;
  let instance_shareowner: any;
  let accounts: any;
  var addressNull: string;
  const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  before(async function() {
    addressNull = "0x0000000000000000000000000000000000000000";
    accounts = await ethers.getSigners();
    instance_busd = await (await ethers.getContractFactory("TokenExample")).deploy();
    await instance_busd.deployed();

    instance_shareowner = [];
    const ShareOwner = await ethers.getContractFactory("ShareOwner");
    instance_shareowner[0] = await ShareOwner.deploy();
    instance_shareowner[1] = await ShareOwner.deploy();
    instance_shareowner[2] = await ShareOwner.deploy();
    instance_shareowner[3] = await ShareOwner.deploy();
    instance_shareowner[4] = await ShareOwner.deploy();
    instance_shareowner[5] = await ShareOwner.deploy();
    instance_shareowner[6] = await ShareOwner.deploy();
    instance_shareowner[7] = await ShareOwner.deploy();
    instance_shareowner[8] = await ShareOwner.deploy();
    instance_shareowner[9] = await ShareOwner.deploy();
    instance_shareowner[10] = await ShareOwner.deploy();
    instance_shareowner[11] = await ShareOwner.deploy();

    let address_shareowner = await instance_shareowner.map((d: any) => d.address);
    instance_matrix = await (await ethers.getContractFactory("Matrix")).deploy(instance_busd.address, address_shareowner);
    await instance_matrix.deployed();
  });

  it("1. Prepare", async () => {
    await instance_busd.connect(accounts[1]).faucet("1000000000000000000000");
    await instance_busd.connect(accounts[1]).increaseAllowance(instance_matrix.address, "1000000000000000000000");

    await instance_busd.connect(accounts[2]).faucet("5000000000000000000000");
    await instance_busd.connect(accounts[2]).increaseAllowance(instance_matrix.address, "5000000000000000000000");
  });

  it("2. Registration", async () => {
  });
});