import { HardhatUserConfig, vars } from "hardhat/config"
import "dotenv/config"
import "@nomicfoundation/hardhat-toolbox-viem"

const ALCHEMY_API_KEY = process.env["ALCHEMY_API_KEY"]!
const WALLET_PRIVATE_KEY = process.env["TEST_WALLET_PRIVATE_KEY"]!

const config: HardhatUserConfig = {
    solidity: "0.8.24",
    networks: {
        sepolia: {
            url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts: [WALLET_PRIVATE_KEY],
        },
    },
}

export default config
