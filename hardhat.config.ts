import "@nomicfoundation/hardhat-toolbox";
import 'dotenv/config';
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.7.6",
      },
      {
        version: "0.8.7",
        settings: {},
      },
    ],
  },
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.RPC_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY??'']
    }
  }
};

export default config;
