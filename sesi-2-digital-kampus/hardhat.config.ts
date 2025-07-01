import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import { vars } from "hardhat/config";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "./tasks/account";
import * as dotenv from "dotenv";
dotenv.config();


const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      metadata: {
        bytecodeHash: "none", // ⬅ prevents IPFS-hash mismatch
        useLiteralContent: true, // ⬅ embeds the full source in metadata
      },
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  sourcify: {
    enabled: true,
    apiUrl: "https://sourcify-api-monad.blockvision.org",
    browserUrl: "https://testnet.monadexplorer.com",
  },
  networks: {
    monad: {
      url: "https://testnet-rpc.monad.xyz/",
    },
    // Konfigurasi untuk Monad Testnet
    monadTestnet: {
      url: "https://testnet-rpc.monad.xyz/",
      chainId: 10143,
      accounts: process.env.PRIVATE_KEY ? [`0x${process.env.PRIVATE_KEY}`] : [],
      gasPrice: "auto",
    },
  },
  etherscan: {
    enabled: false,
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
