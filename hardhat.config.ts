import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-deploy";
// upgradable plugin
import "@matterlabs/hardhat-zksync-upgradable";
import { config as dotEnvConfig } from "dotenv";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import * as tdly from "@tenderly/hardhat-tenderly";

// tdly.setup({ automaticVerifications: true });
dotEnvConfig();

import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {},
  },
  defaultNetwork: "lineaMainnet",
  networks: {
    goerli: {
      zksync: false,
      ethNetwork: "goerli",
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: {
        mnemonic: process.env.mnemonic,
      },
    },
    hardhat: {
      chainId: 1337,
    },
    zkSyncTestnet: {
      zksync: true,
      ethNetwork: "goerli",
      url: "https://testnet.era.zksync.dev",
    },
    zkSyncMainnet: {
      zksync: true,
      ethNetwork: "mainnet",
      url: "https://mainnet.era.zksync.io",
    },
    optimismGoerli: {
      zksync: false,
      ethNetwork: "goerli",
      url: "https://optimism-goerli.publicnode.com",
    },
    baseGoerli: {
      zksync: false,
      ethNetwork: "goerli",
      url: "https://goerli.base.org",
      gasPrice: 1000000,
      accounts: {
        mnemonic: process.env.mnemonic,
      },
    },
    arbGoerli: {
      zksync: false,
      chainId: 421613,
      ethNetwork: "goerli",
      url: "https://rpc.goerli.arbitrum.gateway.fm",
      accounts: {
        mnemonic: process.env.mnemonic,
      },
    },
    lineaMainnet: {
      zksync: false,
      ethNetwork: "mainnet",
      url: "https://linea.drpc.org",
    },
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  tenderly: {
    username: "petergriffin023", // tenderly username (or organization name)
    project: "tenderly", // project name
    privateVerification: true, // if true, contracts will be verified privately, if false, contracts will be verified publicly
  },
};

export default config;
