// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "@openzeppelin-contracts-5.0.1/utils/Strings.sol";
import {Proof} from "vlayer-0.1.0/Proof.sol";
import {Prover} from "vlayer-0.1.0/Prover.sol";
import {Web, WebProof, WebProofLib, WebLib} from "vlayer-0.1.0/WebProof.sol";

function fromHexChar(uint8 c) pure returns (uint8) {
    if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
        return c - uint8(bytes1("0"));
    }
    if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
        return 10 + c - uint8(bytes1("a"));
    }
    if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
        return 10 + c - uint8(bytes1("A"));
    }
    revert("fail");
}

function fromHex(string memory s) pure returns (bytes memory) {
    bytes memory ss = bytes(s);
    require(ss.length % 2 == 0, "Must be even"); // length must be even
    bytes memory r = new bytes(ss.length / 2);
    // Skipping 0x
    for (uint i = 1; i < ss.length / 2; ++i) {
        r[i] = bytes1(
            fromHexChar(uint8(ss[2 * i])) *
                16 +
                fromHexChar(uint8(ss[2 * i + 1]))
        );
    }
    return r;
}

contract WebProofProver is Prover {
    using Strings for string;
    using WebProofLib for WebProof;
    using WebLib for Web;

    string constant RPC_URL = "https://sepolia.optimism.io/";
    string constant TWITTER_URL = "https://api.x.com/2/tweets/1857667225852826080";

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function proveCopytrading(
        WebProof calldata webProof
    )
        public
        view
        returns (Proof memory, string memory, bytes memory, address, uint256)
    {
        Web memory web = webProof.recover(RPC_URL);

        string memory txHash = web.jsonGetString("result.hash");
        bytes memory txInput = fromHex(web.jsonGetString("result.input"));
        address txTo = bytesToAddress(fromHex(web.jsonGetString("result.to")));
        address txFrom = bytesToAddress(
            fromHex(web.jsonGetString("result.from"))
        );
        uint256 txValue = uint256(
            uint160(bytes20(fromHex(web.jsonGetString("result.value"))))
        );

        return (proof(), txHash, txInput, txTo, txValue);
    }
    function proveBullishPost(
        WebProof calldata webProof,
        string calldata bullishRegex
    )
        public
        view
        returns (Proof memory, string memory, string memory, string memory)
    {
        Web memory web = webProof.recover(TWITTER_URL);

        string memory text = web.jsonGetString("data.text");
        string memory id = web.jsonGetString("data.id");

        return (proof(), text, id, bullishRegex);
    }
}
