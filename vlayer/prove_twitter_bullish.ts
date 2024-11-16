import { createVlayerClient } from "@vlayer/sdk";
import proverSpec from "../out/WebProofProver.sol/WebProofProver";
import verifierSpec from "../out/WebProofVerifier.sol/WebProofVerifier";
import tls_proof from "./simple_proof_api.x.com.json";
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

  const bullishRegex = '^.*real potential.*$';

  const hash = await vlayer.prove({
    address: prover,
    functionName: "proveBullishPost",
    proverAbi: proverSpec.abi,
    args: [
      {
        webProofJson: JSON.stringify(webProof),
      },
      bullishRegex
    ],
    chainId: chain.id,
  });
  const result = await vlayer.waitForProvingResult(hash);
  const [proof, text, id] = result;
  console.log("Has Proof");

  console.log("Verifying...");

  const txHash = await ethClient.writeContract({
    address: verifier,
    abi: verifierSpec.abi,
    functionName: "verifyBullishPost",
    args: [proof, text, id, bullishRegex],
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
