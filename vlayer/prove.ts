import { createVlayerClient } from "@vlayer/sdk";
import proverSpec from "../out/WebProofProver.sol/WebProofProver";
import verifierSpec from "../out/WebProofVerifier.sol/WebProofVerifier";
import tls_proof from "./tls_proof.json";
import * as assert from "assert";
import { encodePacked, isAddress, keccak256 } from "viem";

import {
  getConfig,
  createContext,
  deployVlayerContracts,
  writeEnvVariables,
} from "@vlayer/sdk/config";

const notaryPubKey =
  "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEBv36FI4ZFszJa0DQFJ3wWCXvVLFr\ncRzMG5kaTeHGoSzDu6cFqx3uEWYpFGo6C0EOUgf+mEgbktLrXocv5yHzKg==\n-----END PUBLIC KEY-----\n";

const { prover, verifier } = await deployVlayerContracts({
  proverSpec,
  verifierSpec,
});

writeEnvVariables(".env", {
  VITE_PROVER_ADDRESS: prover,
  VITE_VERIFIER_ADDRESS: verifier,
});

const config = getConfig();
const { chain, ethClient, account, proverUrl, confirmations } =
  await createContext(config);

const vlayer = createVlayerClient({
  url: proverUrl,
});

await testSuccessProvingAndVerification();
// await testFailedProving();

async function testSuccessProvingAndVerification() {
  console.log("Proving...");

  const webProof = { tls_proof: tls_proof, notary_pub_key: notaryPubKey };

  const hash = await vlayer.prove({
    address: prover,
    functionName: "main",
    proverAbi: proverSpec.abi,
    args: [
      {
        webProofJson: JSON.stringify(webProof),
      },
    ],
    chainId: chain.id,
  });
  const result = await vlayer.waitForProvingResult(hash);
  const [proof, txHash_, txInput, txTo, txValue] = result;
  console.log("Has Proof");

  console.log("Verifying...");

  // const txHash_ = '0x5a34d74b17fc7af7da4b9ca3dc2b03ef4a38d24d0525017e904faac541cc8c44';
  // const txInput = '0x';
  // const txTo = '0xb6f0fd9f26c05e163e108aa86165697d2dbc258c';
  // const txValue = '0xb147c91e4ac000';

  const txHash = await ethClient.writeContract({
    address: verifier,
    abi: verifierSpec.abi,
    functionName: "verify",
    args: [proof, txHash_, txInput, txTo, txValue],
    chain,
    account: account,
  });

  await ethClient.waitForTransactionReceipt({
    hash: txHash,
    confirmations,
    retryCount: 60,
    retryDelay: 1000,
  });

  console.log("Verified!");
}

// async function testFailedProving() {

//   console.log("Proving...");

//   const wrongWebProof = { tls_proof: tls_proof, notary_pub_key: "wrong" };

//   try {
//     const hash = await vlayer.prove({
//       address: prover,
//       functionName: "main",
//       proverAbi: proverSpec.abi,
//       args: [
//         {
//           webProofJson: JSON.stringify(wrongWebProof),
//         },
//       ],
//       chainId: chain.id,
//     });
//     await vlayer.waitForProvingResult(hash);
//     throw new Error("Proving should have failed!");
//   } catch (error) {
//     assert.ok(error instanceof Error, `Invalid error returned: ${error}`);
//     assert.equal(
//       error.message,
//       "Error response: Host error: TravelCallExecutor error: EVM transact error: ASN.1 error: PEM error: PEM preamble contains invalid data (NUL byte) at line 1 column 22883",
//       `Error with wrong message returned: ${error.message}`
//     );
//     console.log("Proving failed as expected with message:", error.message);
//   }
// }
