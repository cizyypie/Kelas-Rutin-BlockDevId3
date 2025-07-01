const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TokenSuiteModule", (m) => {
  // Deploy contracts
  const campusCredit = m.contract("CampusCredit");
  const studentID = m.contract("StudentID");
  const campusBadge = m.contract("CampusBadge");

  // Use account[0] as deployer

  const deployer = m.getAccount(0);
  const fee = "100";

  // Call registerMerchant(address merchant, uint256 fee)
  m.call(campusCredit, "registerMerchant", [deployer, fee]); // 100 units (adjust as needed)

  return { campusCredit, studentID, campusBadge };
});
