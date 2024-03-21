// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Betallica is Ownable {
    enum Choice {
        None,
        Head,
        Tail
    }

    enum Stage {
        AcceptingBet,
        RevealBet,
        Finished
    }

    struct Bet {
        bytes32 choiceHash;
        uint value;
        Choice choice;
    }

    mapping(address => Bet) private bets;

    uint private prizePool;
    uint private winnerCount;
    bytes32 private choiceHash;
    Choice private choice;
    Stage private currentStage;

    event ChoiceInitialized(bytes32 hash);
    event ChoiceRevealed(string choice);

    modifier atStage(Stage _stage) {
        require(currentStage == _stage, "Wrong stage");
        _;
    }

    modifier nextStage() {
        _;
        currentStage = Stage(uint(currentStage) + 1);
    }

    constructor(bytes32 _choiceHash) Ownable(msg.sender) {
        choiceHash = _choiceHash;
        choice = Choice.None;
        currentStage = Stage.AcceptingBet;
        prizePool = 0;
        winnerCount = 0;
        emit ChoiceInitialized(choiceHash);
    }

    function parseChoice(string memory _choice) internal pure returns (Choice) {
        if (keccak256(abi.encodePacked(_choice)) == "Head") {
            return Choice.Head;
        } else if (keccak256(abi.encodePacked(_choice)) == "Tail") {
            return Choice.Tail;
        } else {
            revert("Cannot determine choice");
        }
    }

    modifier correctValue(
        Choice _choice,
        string memory _salt,
        bytes32 _hash
    ) {
        require(_choice != Choice.None, "Choice must be set");
        require(
            keccak256(
                abi.encodePacked(
                    _choice == Choice.Head ? "Head" : "Tail",
                    _salt
                )
            ) == _hash,
            "Wrong hash"
        );
        _;
    }

    function placeBet(
        bytes32 _choiceHash
    ) external payable atStage(Stage.AcceptingBet) {
        bets[msg.sender] = Bet({
            choiceHash: _choiceHash,
            value: msg.value,
            choice: Choice.None
        });
        prizePool += msg.value;
    }

    function revealChoice(
        string memory _choice,
        string memory _salt
    )
        external
        onlyOwner
        atStage(Stage.AcceptingBet)
        correctValue(parseChoice(_choice), _salt, choiceHash)
        nextStage
    {
        choice = parseChoice(_choice);
        emit ChoiceRevealed(_choice);
    }

    function revealBet(
        string memory _choice,
        string memory _salt
    )
        external
        atStage(Stage.RevealBet)
        correctValue(parseChoice(_choice), _salt, bets[msg.sender].choiceHash)
    {
        Choice userChoice = parseChoice(_choice);
        bets[msg.sender].choice = userChoice;
        if (userChoice == choice) {
            prizePool -= bets[msg.sender].value;
            winnerCount += 1;
        }
    }

    function closeReveal()
        external
        onlyOwner
        atStage(Stage.RevealBet)
        nextStage
    {}

    function withdrawBets() external atStage(Stage.Finished) {
        require(bets[msg.sender].choice == choice, "You are losing the bet");
        uint refundedValue = bets[msg.sender].value + (prizePool / winnerCount);
        msg.sender.call{gas: 4000, value: refundedValue}("");
    }
}
