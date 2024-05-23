import { HardhatUserConfig } from "hardhat/config";
import '@typechain/hardhat'
import '@nomicfoundation/hardhat-ethers'
import "@nomicfoundation/hardhat-toolbox";

// output contract size
import 'hardhat-contract-sizer';

// proxy
import '@openzeppelin/hardhat-upgrades';

// load .env config
import { config as dotenvConfig } from 'dotenv';
import { resolve } from 'path';

dotenvConfig({ path: resolve(__dirname, './.env') });

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      chainId: 31337,
    }
  },
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
  },
  contractSizer: {
    disambiguatePaths: true,
    runOnCompile: true,
    strict: true
  },
};

export default config;
