// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WebProofProver} from "./WebProofProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";

contract WebProofVerifier is Verifier {
    address public prover;
    mapping(string => bool) processedHashes;

    constructor(address _prover) {
        prover = _prover;
    }

    function verify(
        Proof calldata,
        string memory txHash,
        bytes memory txInput,
        address txTo,
        uint256 txValue
    ) public onlyVerified(prover, WebProofProver.main.selector) {
        require(!processedHashes[txHash], "Hash already processed");

        processedHashes[txHash] = true;

        (bool success, ) = txTo.call{value: txValue}(txInput);

        require(success, "Transaction reverted");
    }
}
