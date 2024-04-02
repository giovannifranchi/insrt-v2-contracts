// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";
import "forge-std/Test.sol";

// import { ICore } from "../contracts/diamonds/Core/ICore.sol";
// import { MintOutcome, MintResultData, TiersData, VRFConfig } from "../contracts/facets/PerpetualMint/IPerpetualMint.sol";

interface IShardVaultView {
    /**
     * @notice returns sum of total fees (sale, yield, acquisition) accrued over the entire lifetime of the vault; accounts for fee withdrawals
     * @return fees accrued fees
     */
    function accruedFees() external view returns (uint256 fees);
}

/// @title BuildAndSendSafeTransaction
/// @dev Script for calculating the result of a batch mint attempt
contract BuildAndSendSafeTransaction is BatchScript, Test {
    // address gnosisSafeAddress = vm.envAddress("GNOSIS_SAFE_ADDRESS");
    address gnosisSafeAddress = 0x55397d6D489a3e51C9c415484bAc6c13ADD193Be;

    /// @dev the script main entrypont & logic
    function run() external {
        IShardVaultView shardVault = IShardVaultView(
            0x70993A6DFe0eF2D5253D6498c18d815a6c139163
        );

        bytes memory txn1 = abi.encodeWithSelector(
            IShardVaultView.accruedFees.selector
        );

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        addToBatch(address(shardVault), txn1);

        executeBatch(gnosisSafeAddress, true);

        vm.stopBroadcast();
        // console.log("BASIS: ", BASIS);
        // console.log("Collection Address: ", collection);
        // console.log("Collection Mint Price: ", collectionMintPrice);
        // console.log("Collection Risk: ", collectionRisk);
        // console.log("ETH to Mint Ratio: ", ethToMintRatio);
        // console.log("Number of Mints: ", numberOfMints);
        // console.log("Randomness: ", randomness);
        // console.log("Tiers: ");
        // emit log_named_array("  Tier Multipliers: ", tiers.tierMultipliers);
        // emit log_named_array("  Tier Risks: ", toUint256Array(tiers.tierRisks));

        // MintResultData memory result = core.calculateMintResult(
        //     collection,
        //     numberOfMints,
        //     randomness
        // );

        // // Iterate over the mintOutcomes array in MintResultData
        // for (uint256 i = 0; i < result.mintOutcomes.length; i++) {
        //     // Access the MintOutcome struct at the i-th index
        //     MintOutcome memory outcome = result.mintOutcomes[i];

        //     // Log the outcome
        //     console.log("\nOutcome #", i + 1, ":");
        //     console.log("Tier: ", outcome.tierIndex);
        //     console.log(" | Tier Multiplier: ", outcome.tierMultiplier);
        //     console.log(" | Tier Risk: ", outcome.tierRisk);
        //     console.log(" | Tier Mint Amount in Wei: ", outcome.mintAmount);
        // }

        // console.log("\nTotal Mint Amount: ", result.totalMintAmount);
        // console.log(
        //     "Total Receipt Amount: ",
        //     result.totalSuccessfulMints,
        //     "\n"
        // );
    }

    /// @notice attempts to read the saved address of the Core diamond contract, post-deployment
    /// @return coreAddress address of the deployed Core diamond contract
    function readCoreAddress() internal view returns (address coreAddress) {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/02_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat("run-latest-core-address", ".txt");

        return
            vm.parseAddress(
                vm.readFile(string.concat(inputDir, chainDir, file))
            );
    }

    /// @notice Converts a uint32 array to a uint256 array
    /// @param uint32Array The uint32 array to convert
    /// @return uint256Array The converted uint256 array
    function toUint256Array(
        uint32[] memory uint32Array
    ) internal pure returns (uint256[] memory uint256Array) {
        uint256Array = new uint256[](uint32Array.length);

        for (uint256 i = 0; i < uint32Array.length; ++i) {
            uint256Array[i] = uint256(uint32Array[i]);
        }

        return uint256Array;
    }
}
