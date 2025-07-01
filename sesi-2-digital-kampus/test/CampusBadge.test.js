const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CampusBadge", function () {
  let campusBadge;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    const CampusBadge = await ethers.getContractFactory("CampusBadge");
    campusBadge = await CampusBadge.deploy();
    await campusBadge.waitForDeployment();
  });

  it("should deploy correctly", async function () {
    expect(await campusBadge.getAddress()).to.be.properAddress;
  });

  it("should allow certificate creation and issuance", async function () {
    const certificateName = "Web3 Development";
    const maxSupply = 100;
    const certificateURI = "ipfs://web3cert";
    
    // Create certificate type first and wait for transaction
    const createTx = await campusBadge.createCertificateType(
      certificateName, 
      maxSupply, 
      certificateURI
    );
    await createTx.wait(); // Wait for transaction to be mined
    
    // The first certificate will have ID = CERTIFICATE_BASE + 0 = 1000
    const certificateId = 1000;
    
    // Issue certificate to address
    await campusBadge.issueCertificate(
      addr1.address, 
      certificateId, 
      "Additional data"
    );
    
    expect(await campusBadge.balanceOf(addr1.address, certificateId)).to.equal(1);
  });

  it("should fail if non-minter tries to issue", async function () {
    const certificateName = "Web3 Development";
    const maxSupply = 100;
    const certificateURI = "ipfs://web3cert";
    
    const createTx = await campusBadge.createCertificateType(
      certificateName, 
      maxSupply, 
      certificateURI
    );
    await createTx.wait();
    
    const certificateId = 1000;
    
    await expect(
      campusBadge.connect(addr1).issueCertificate(
        addr1.address, 
        certificateId, 
        "Additional data"
      )
    ).to.be.reverted
  });
});
