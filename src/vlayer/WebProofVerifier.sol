// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WebProofProver} from "./WebProofProver.sol";

import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Verifier} from "vlayer-0.1.0/Verifier.sol";


contract WebProofVerifier is Verifier {

    address public prover;
    mapping(string => bool) processedHashes;
    mapping(string => bool) postIdsProcessed;
    
    constructor(address _prover) {
        prover = _prover;
    }

    function verifyCopytrading(
        Proof calldata,
        string memory txHash,
        bytes memory txInput,
        address txTo,
        uint256 txValue
    ) public onlyVerified(prover, WebProofProver.proveCopytrading.selector) {
        require(!processedHashes[txHash], "Hash already processed");

        processedHashes[txHash] = true;

        (bool success, ) = txTo.call{value: txValue}(txInput);

        require(success, "Transaction reverted");
    }

    function verifyBullishPost(
        Proof calldata,
        string memory text,
        string memory id
    ) public onlyVerified(prover, WebProofProver.proveBullishPost.selector) {
        require(!postIdsProcessed[id], "Post already processed");

        postIdsProcessed[id] = true;
    }
}
