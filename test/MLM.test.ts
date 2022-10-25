import { expect } from "chai";
import { ethers } from "hardhat";

describe("MLM", () => {
  let instance_usdc: any;
  let instance_mlm: any;
  let accounts: any;
  var addressNull: string;

  before(async function() {
    addressNull = "0x0000000000000000000000000000000000000000";
    accounts = await ethers.getSigners();
    instance_usdc = await (await ethers.getContractFactory("TokenExample")).deploy();
    await instance_usdc.deployed();

    instance_mlm = await (await ethers.getContractFactory("MLM")).deploy(instance_usdc.address);
    await instance_mlm.deployed();
  });

  it("1. Prepare", async () => {
    await instance_usdc.connect(accounts[1]).faucet("100000000");
    await instance_usdc.connect(accounts[1]).increaseAllowance(instance_mlm.address, "100000000");

    await instance_usdc.connect(accounts[2]).faucet("500000000");
    await instance_usdc.connect(accounts[2]).increaseAllowance(instance_mlm.address, "500000000");
  });

  it("2. Mint", async () => {
    await expect(instance_mlm.connect(accounts[1]).mint("0", "3"))
    .to.emit(instance_mlm, 'PurchasePosition')
    .withArgs(accounts[1].address, "1", 3, addressNull, "0");
    expect(Number(await instance_usdc.balanceOf(instance_mlm.address))).to.equal(100000000);

    await expect(instance_mlm.connect(accounts[2]).mint("1", "0"))
    .to.emit(instance_mlm, 'PurchasePosition')
    .withArgs(accounts[2].address, "2", 0, accounts[1].address, "1");
    expect(Number(await instance_usdc.balanceOf(accounts[1].address))).to.equal(8000000);
    expect(Number(await instance_usdc.balanceOf(instance_mlm.address))).to.equal(102000000);
  });

  it("3. Upgrade Tier", async () => {
    await expect(instance_mlm.connect(accounts[2]).upgrade("2", "3"))
    .to.emit(instance_mlm, 'UpgradePosition')
    .withArgs(accounts[2].address, "2", 3, 0);
    expect(Number(await instance_usdc.balanceOf(accounts[1].address))).to.equal(88000000);
    expect(Number(await instance_usdc.balanceOf(instance_mlm.address))).to.equal(122000000);
  });

  it("4. Release Share", async () => {
    await instance_mlm.releaseShare();
    expect(Number(await instance_usdc.balanceOf("0x096222480b6529B0a7cf150846f4D85AEcf6f5bC"))).to.equal(91500000);
    expect(Number(await instance_usdc.balanceOf("0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7"))).to.equal(30500000);
  });

  it("5. Investment", async () => {
    await instance_usdc.connect(accounts[3]).faucet("20000000");
    await instance_usdc.connect(accounts[3]).increaseAllowance(instance_mlm.address, "20000000");

    await instance_mlm.connect(accounts[3]).investment();
    expect(Number(await instance_usdc.balanceOf(accounts[3].address))).to.equal(0);
    expect(Number(await instance_usdc.balanceOf("0x096222480b6529B0a7cf150846f4D85AEcf6f5bC"))).to.equal(106500000);
    expect(Number(await instance_usdc.balanceOf("0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7"))).to.equal(35500000);

    await expect(instance_mlm.connect(accounts[2]).mint("0", "3"))
    .to.emit(instance_mlm, 'PurchasePosition')
    .withArgs(accounts[2].address, "3", 3, addressNull, "0");
    expect(Number(await instance_usdc.balanceOf(instance_mlm.address))).to.equal(100000000);

    await instance_mlm.releaseShare();
    expect(Number(await instance_usdc.balanceOf(accounts[3].address))).to.equal(30000000);
    expect(Number(await instance_usdc.balanceOf("0x096222480b6529B0a7cf150846f4D85AEcf6f5bC"))).to.equal(159000000);
    expect(Number(await instance_usdc.balanceOf("0xE7FDBFec446CA0010da257DE450dC6f6e9b13DF7"))).to.equal(53000000);
  });

  it("6. Set Custom URI", async () => {
    expect(await instance_mlm.tokenURI("1")).to.equal("3");
    await instance_mlm.setCustomURI("ipfs://0x/");
    expect(await instance_mlm.tokenURI("1")).to.equal("ipfs://0x/3");
  });
});