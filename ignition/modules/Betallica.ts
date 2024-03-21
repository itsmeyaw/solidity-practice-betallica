import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import { parseEther, keccak256, encodePacked } from "viem"

const BetallicaModule = buildModule("BetallicaModule", (m) => {
    const salt = "SOME_SECRET"
    const choice = "Head"
    const hash = keccak256(encodePacked(["string", "string"], [salt, choice]))
    const choiceHash = m.getParameter("_choiceHash", hash)
    const token = m.contract("Betallica", [choiceHash])
    return { token }
})

export default BetallicaModule
