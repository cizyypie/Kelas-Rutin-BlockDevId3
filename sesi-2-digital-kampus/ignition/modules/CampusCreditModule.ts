// ignition/modules/CampusCreditModule.ts
import { buildModule } from "@nomicfoundation/ignition-core";

const CampusCreditModule = buildModule("CampusCreditModule", (m) => {
  const campusCredit = m.contract("CampusCredit", []);

  return { campusCredit };
});

export default CampusCreditModule;
