const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StudentID", function () {
  let studentID;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    const StudentID = await ethers.getContractFactory("StudentID");
    studentID = await StudentID.deploy();
    await studentID.waitForDeployment();
  });

  it("should deploy and allow issuing student ID", async function () {
    const nim = "12345678";
    const studentName = "John Doe";
    const major = "Computer Science";
    const metadataURI = "ipfs://studentdata";
    
    // Issue student ID using the actual function signature
    await studentID.issueStudentID(
      addr1.address, 
      nim,
      studentName, 
      major,
      metadataURI
    );
    
    // Check if student ID was issued (token ID should be 0 for first minted token)
    expect(await studentID.balanceOf(addr1.address)).to.equal(1);
    expect(await studentID.ownerOf(0)).to.equal(addr1.address);
    
    // Check if student data was stored correctly
    const studentData = await studentID.studentData(0);
    expect(studentData.nim).to.equal(nim);
    expect(studentData.name).to.equal(studentName);
    expect(studentData.major).to.equal(major);
    expect(studentData.isActive).to.be.true;
  });

  it("should fail if non-owner tries to issue", async function () {
    const nim = "12345678";
    const studentName = "John Doe";
    const major = "Computer Science";
    const metadataURI = "ipfs://studentdata";
    
    await expect(
      studentID.connect(addr1).issueStudentID(
        addr1.address, 
        nim,
        studentName, 
        major,
        metadataURI
      )
    ).to.be.reverted
  });
});