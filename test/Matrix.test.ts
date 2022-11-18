import { expect } from "chai";
import { ethers, waffle } from "hardhat";

describe("Matrix", () => {
  let instance_busd: any;
  let instance_matrix: any;
  let instance_shareowner: any;
  let address_shareowner: any;
  let provider: any;
  let accounts: any;
  let addressOwner: any;
  var addressNull: string;
  const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  before(async function() {
    provider = waffle.provider;
    addressOwner = ["0x096222480b6529B0a7cf150846f4D85AEcf6f5bC", "0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7"];
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

    address_shareowner = await instance_shareowner.map((d: any) => d.address);
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
    await expect(instance_matrix.connect(accounts[1]).registration(addressNull, { value: "2000000000000000000" }))
    .to.emit(instance_matrix, 'Registration');

    // Get Ether
    expect(Number(await provider.getBalance(addressOwner[0]))).to.equal(1500000000000000000);
    expect(Number(await provider.getBalance(addressOwner[1]))).to.equal(500000000000000000);
    // Get Token BUSD
    expect(Number(await instance_busd.balanceOf(address_shareowner[0]))).to.equal(6000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[1]))).to.equal(3000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[2]))).to.equal(1000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[3]))).to.equal(200000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[4]))).to.equal(200000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[5]))).to.equal(300000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[6]))).to.equal(300000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[7]))).to.equal(500000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[8]))).to.equal(700000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[9]))).to.equal(800000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[10]))).to.equal(1000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[11]))).to.equal(2000000000000000000);
  });
});