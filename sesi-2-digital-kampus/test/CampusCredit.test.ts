// test/CampusCredit.test.ts
import { expect } from "chai";
import { ethers } from "hardhat";
import CampusCreditModule from "../ignition/modules/CampusCreditModule";
import { ignition } from "hardhat";
import { CampusCredit } from "../typechain-types";

describe("CampusCredit", function () {
  let campusCredit: CampusCredit;
  let deployer: any;
  let student: any;
  let merchant: any;

  beforeEach(async () => {
    [deployer, student, merchant] = await ethers.getSigners();

    const { campusCredit: deployedContract } = await ignition.deploy(CampusCreditModule);
    
    // Fix: Cast the connected contract to CampusCredit type
    campusCredit = deployedContract.connect(deployer) as CampusCredit;
  });

  // Also fix the ethers.utils syntax for ethers v6
  it("should mint tokens to a student", async function () {
    const amount = ethers.parseEther("1000"); // Changed from ethers.utils.parseEther

    await campusCredit.mint(student.address, amount);
    const balance = await campusCredit.balanceOf(student.address);

    expect(balance).to.equal(amount);
  });

  it("should pause and unpause the contract", async function () {
  await campusCredit.pause();
  await expect(
    campusCredit.transfer(student.address, 100)
  ).to.be.revertedWithCustomError(campusCredit, "EnforcedPause"); // ← New line

  await campusCredit.unpause();
  await campusCredit.transfer(student.address, 100);
  const balance = await campusCredit.balanceOf(student.address);
  expect(balance).to.equal(100);
});

  it("should register a merchant", async function () {
    const name = "Cafeteria";
    await campusCredit.registerMerchant(merchant.address, name);

    expect(await campusCredit.isMerchant(merchant.address)).to.equal(true);
    expect(await campusCredit.merchantName(merchant.address)).to.equal(name);
  });
});