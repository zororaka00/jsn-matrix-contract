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

  before(async function() {
    provider = waffle.provider;
    addressOwner = ["0x75552A8202076e707F37cf6c5F0782BCA054a6F3", "0xa8bf3aC4f567384F2f44B4E7C6d11b7664749f35"];
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

    await instance_busd.connect(accounts[2]).faucet("1000000000000000000000");
    await instance_busd.connect(accounts[2]).increaseAllowance(instance_matrix.address, "1000000000000000000000");

    await instance_busd.connect(accounts[3]).faucet("1000000000000000000000");
    await instance_busd.connect(accounts[3]).increaseAllowance(instance_matrix.address, "1000000000000000000000");
  });

  it("2. Registration", async () => {
    // Less Than 2 MATIC
    expect(instance_matrix.connect(accounts[1]).registration(addressNull, { value: "1000000000000000000" }))
    .to.be.revertedWith("Less than 2 Matic");
    // Success Registration
    await expect(instance_matrix.connect(accounts[1]).registration(addressNull, { value: "2000000000000000000" }))
    .to.emit(instance_matrix, 'Registration');
    // Repeat Registration
    expect(instance_matrix.connect(accounts[1]).registration(addressNull, { value: "2000000000000000000" }))
    .to.be.revertedWith("Address already registration");

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

  it("3. Release Share Owner", async () => {
    await instance_matrix.releaseShareOwner();

    expect(Number(await instance_busd.balanceOf(addressOwner[0]))).to.equal(12000000000000000000);
    expect(Number(await instance_busd.balanceOf(addressOwner[1]))).to.equal(4000000000000000000);
  });

  it("4. Investment", async () => {
    expect((Number(await provider.getBalance(accounts[5].address)) / 1e+18).toFixed(0)).to.equal("10000"); // 10.000 ether
    await instance_matrix.connect(accounts[5]).invest({ value: "2000000000000000000" });
    expect((Number(await provider.getBalance(accounts[5].address)) / 1e+18).toFixed(0)).to.equal("9998"); // 9.998 ether
    expect(Number(await provider.getBalance(addressOwner[0]))).to.equal(3000000000000000000);
    expect(Number(await provider.getBalance(addressOwner[1]))).to.equal(1000000000000000000);
    // increase pendingClaimInvestor
    expect(Number(await instance_matrix.pendingClaimInvestor())).to.equal(3000000000000000000);
    
    await expect(instance_matrix.connect(accounts[2]).registration(accounts[1].address, { value: "2000000000000000000" }))
    .to.emit(instance_matrix, 'Registration');
    // decrease pendingClaimInvestor
    expect(Number(await instance_matrix.pendingClaimInvestor())).to.equal(1000000000000000000);
    // Get Ether
    expect((Number(await provider.getBalance(accounts[5].address)) / 1e+18).toFixed(0)).to.equal("10000"); // 10.000 ether
    // Get Token BUSD
    expect(Number(await instance_busd.balanceOf(accounts[1].address)))
    .to.equal(990000000000000000000); // 1000 (faucet) - 16 (registration) + 6 (bonus level 1) = 990
    expect(Number(await instance_busd.balanceOf(address_shareowner[0]))).to.equal(3000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[1]))).to.equal(1000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[2]))).to.equal(200000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[3]))).to.equal(200000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[4]))).to.equal(300000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[5]))).to.equal(300000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[6]))).to.equal(500000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[7]))).to.equal(700000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[8]))).to.equal(800000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[9]))).to.equal(1000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[10]))).to.equal(2000000000000000000);

    
    await expect(instance_matrix.connect(accounts[3]).registration(accounts[2].address, { value: "2000000000000000000" }))
    .to.emit(instance_matrix, 'Registration');
    // decrease pendingClaimInvestor
    expect(Number(await instance_matrix.pendingClaimInvestor())).to.equal(0);
    // Get Ether
    expect((Number(await provider.getBalance(accounts[5].address)) / 1e+18).toFixed(0)).to.equal("10001"); // 10.001 ether
    expect(Number(await provider.getBalance(addressOwner[0]))).to.equal(3750000000000000000); // 2.25 ether
    expect(Number(await provider.getBalance(addressOwner[1]))).to.equal(1250000000000000000); // 0.75 ether
    // Get Token BUSD
    expect(Number(await instance_busd.balanceOf(accounts[2].address)))
    .to.equal(990000000000000000000); // 1000 (faucet) - 16 (registration) + 6 (bonus level 1) = 990
    expect(Number(await instance_busd.balanceOf(accounts[1].address)))
    .to.equal(993000000000000000000); // 1000 (faucet) - 16 (registration) + 6 (bonus level 1) + 3 (bonus level 2) = 993
    expect(Number(await instance_busd.balanceOf(address_shareowner[0]))).to.equal(4000000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[1]))).to.equal(1200000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[2]))).to.equal(400000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[3]))).to.equal(500000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[4]))).to.equal(600000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[5]))).to.equal(800000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[6]))).to.equal(1200000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[7]))).to.equal(1500000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[8]))).to.equal(1800000000000000000);
    expect(Number(await instance_busd.balanceOf(address_shareowner[9]))).to.equal(3000000000000000000);
  });
});