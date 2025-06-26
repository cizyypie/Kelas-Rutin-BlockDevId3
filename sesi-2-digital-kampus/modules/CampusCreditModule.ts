import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CampusCreditModule = buildModule("CampusCreditModule", (m) => {
  // Deploy the CampusCredit contract
  const campusCredit = m.contract("CampusCredit", []);

  return { campusCredit };
});

export default CampusCreditModule;