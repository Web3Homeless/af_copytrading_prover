// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WebProofProver} from "./WebProofProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";
import {RegexLib} from "vlayer-0.1.0/Regex.sol";


contract WebProofVerifier is Verifier {
    using RegexLib for string;

    address public prover;
    mapping(string => bool) processedHashes;
    mapping(string => bool) postIdsProcessed;

    mapping(string => bool) bullishRegexes;
    constructor(address _prover, string[] memory bullishRegexes_) {
        prover = _prover;

        for (uint256 i = 0; i < bullishRegexes_.length; i++) {
            bullishRegexes[bullishRegexes_[i]] = true;
        }
    }

    function verifyCopytrading(
        Proof calldata,
        string memory txHash,
        bytes memory txInput,
        address txTo,
        uint256 txValue
    ) public onlyVerified(prover, WebProofProver.proveCopyTrading.selector) {
        require(!processedHashes[txHash], "Hash already processed");

        processedHashes[txHash] = true;

        (bool success, ) = txTo.call{value: txValue}(txInput);

        require(success, "Transaction reverted");
    }

    function verifyBullishPost(
        Proof calldata,
        string memory text,
        string memory id,
        string memory bullishRegex
    ) public onlyVerified(prover, WebProofProver.proveCopyTrading.selector) {
        require(text.matches(bullishRegex), "Text is not bullish");
        require(bullishRegexes[bullishRegex], "Regex is not bullish");
        require(!postIdsProcessed[id], "Post already processed");

        postIdsProcessed[id] = true;
    }
}
