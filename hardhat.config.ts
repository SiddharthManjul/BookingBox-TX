import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const PEGASUS_URL = process.env.PEGASUS_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    pegasus: {
      url: PEGASUS_URL,
      accounts: [PRIVATE_KEY as string]
    }
  }
};

export default config;
