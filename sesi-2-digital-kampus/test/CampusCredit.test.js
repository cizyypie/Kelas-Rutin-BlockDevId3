const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CampusCredit", function () {
  let campusCredit;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    const CampusCredit = await ethers.getContractFactory("CampusCredit");
    campusCredit = await CampusCredit.deploy();
    await campusCredit.waitForDeployment();
  });

  it("should deploy correctly and assign MINTER_ROLE", async function () {
    expect(await campusCredit.getAddress()).to.be.properAddress;
    // Check if owner has MINTER_ROLE
    const MINTER_ROLE = await campusCredit.MINTER_ROLE();
    expect(await campusCredit.hasRole(MINTER_ROLE, owner.address)).to.be.true;
  });

  it("should mint credits to user", async function () {
    const amount = ethers.parseEther("100");
    
    await campusCredit.mint(addr1.address, amount);
    
    expect(await campusCredit.balanceOf(addr1.address)).to.equal(amount);
  });

  it("should reject mint from non-minter", async function () {
    const amount = ethers.parseEther("100");
    
    // Use full error message for compatibility
    await expect(
      campusCredit.connect(addr1).mint(addr1.address, amount)
    ).to.be.reverted
  });
});
