// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { IPerpetualMintViewBlast } from "../../../contracts/facets/PerpetualMint/Blast/IPerpetualMintView.sol";
import { IPerpetualMintViewSupraBlast } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { PerpetualMintViewSupraBlast } from "../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMintView.sol";

/// @title UpgradePerpetualMintViewSupraBlast
/// @dev Deploys a new PerpetualMintViewSupraBlast facet and signs and submits a diamondCut of the PerpetualMintViewSupraBlast facet
/// to the CoreBlast diamond via the Gnosis Safe Transaction Service API
contract UpgradePerpetualMintViewSupraBlast is BatchScript {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // get CoreBlast PerpetualMint diamond address
        address core = vm.envAddress("CORE_BLAST_ADDRESS");

        // get Gnosis Safe (protocol owner) address
        address gnosisSafeAddress = vm.envAddress("GNOSIS_SAFE");

        // get VRF Router address
        address VRF_ROUTER = vm.envAddress("VRF_ROUTER");

        // we only explicitly broadcast facet deployments
        // broadcasting of batch execution gnosis multi-sig transactions is done
        // separately using the Gnosis Safe Transaction Service API
        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMintViewSupraBlast facet
        PerpetualMintViewSupraBlast perpetualMintViewSupraBlast = new PerpetualMintViewSupraBlast(
                VRF_ROUTER
            );

        vm.stopBroadcast();

        console2.log(
            "New PerpetualMintViewSupraBlast Facet Address: ",
            address(perpetualMintViewSupraBlast)
        );
        console2.log("CoreBlast Address: ", core);
        console2.log("VRF Router Address: ", VRF_ROUTER);

        // get new PerpetualMintView + PerpetualMintViewSupraBlast facet cuts
        ICore.FacetCut[]
            memory newPerpetualMintViewFacetCuts = getNewPerpetualMintViewFacetCuts(
                address(perpetualMintViewSupraBlast)
            );

        // get replacement PerpetualMintView + PerpetualMintViewSupraBlast facet cuts
        ICore.FacetCut[]
            memory replacementPerpetualMintViewFacetCuts = getReplacementPerpetualMintViewFacetCuts(
                address(perpetualMintViewSupraBlast)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](5);

        facetCuts[0] = newPerpetualMintViewFacetCuts[0];
        facetCuts[1] = replacementPerpetualMintViewFacetCuts[0];
        facetCuts[2] = replacementPerpetualMintViewFacetCuts[1];
        facetCuts[3] = replacementPerpetualMintViewFacetCuts[2];
        facetCuts[4] = replacementPerpetualMintViewFacetCuts[3];

        bytes memory diamondCutTx = abi.encodeWithSelector(
            IDiamondWritable.diamondCut.selector,
            facetCuts,
            address(0),
            ""
        );

        addToBatch(core, diamondCutTx);

        executeBatch(gnosisSafeAddress, true);
    }

    /// @dev provides the new facet cuts for cutting PerpetualMintView & PerpetualMintViewSupraBlast facets into CoreBlast
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getNewPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](2);

        perpetualMintViewFunctionSelectors[0] = IPerpetualMintView
            .mintEarningsBufferBP
            .selector;

        perpetualMintViewFunctionSelectors[1] = IPerpetualMintView
            .mintForEthConsolationFeeBP
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintViewFacetCut;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMintView facet into CoreBlast
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getReplacementPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ICore.FacetCut memory pausableFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: viewFacetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](25);

        perpetualMintViewFunctionSelectors[0] = IPerpetualMintView
            .accruedConsolationFees
            .selector;

        perpetualMintViewFunctionSelectors[1] = IPerpetualMintView
            .accruedMintEarnings
            .selector;

        perpetualMintViewFunctionSelectors[2] = IPerpetualMintView
            .accruedProtocolFees
            .selector;

        perpetualMintViewFunctionSelectors[3] = IPerpetualMintView
            .BASIS
            .selector;

        perpetualMintViewFunctionSelectors[4] = IPerpetualMintView
            .collectionConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[5] = IPerpetualMintView
            .collectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintViewFunctionSelectors[6] = IPerpetualMintView
            .collectionMintMultiplier
            .selector;

        perpetualMintViewFunctionSelectors[7] = IPerpetualMintView
            .collectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[8] = IPerpetualMintView
            .collectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[9] = IPerpetualMintView
            .collectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[10] = IPerpetualMintView
            .defaultCollectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[11] = IPerpetualMintView
            .defaultCollectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[12] = IPerpetualMintView
            .defaultCollectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[13] = IPerpetualMintView
            .defaultEthToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[14] = IPerpetualMintView
            .ethToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[15] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .SCALE
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[23] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[24] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintViewBlast related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewBlastFunctionSelectors = new bytes4[](
            2
        );

        perpetualMintViewBlastFunctionSelectors[0] = IPerpetualMintViewBlast
            .blastYieldRisk
            .selector;

        perpetualMintViewBlastFunctionSelectors[1] = IPerpetualMintViewBlast
            .calculateMaxClaimableGas
            .selector;

        ICore.FacetCut
            memory perpetualMintViewBlastFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewBlastFunctionSelectors
                });

        // map the PerpetualMintViewSupraBlast related function selectors to their respective interfaces
        bytes4[]
            memory perpetualMintViewSupraBlastFunctionSelectors = new bytes4[](
                1
            );

        perpetualMintViewSupraBlastFunctionSelectors[
            0
        ] = IPerpetualMintViewSupraBlast.calculateMintResultSupraBlast.selector;

        ICore.FacetCut
            memory perpetualMintViewSupraBlastFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewSupraBlastFunctionSelectors
                });

        facetCuts = new ICore.FacetCut[](4);

        facetCuts[0] = pausableFacetCut;
        facetCuts[1] = perpetualMintViewFacetCut;
        facetCuts[2] = perpetualMintViewBlastFacetCut;
        facetCuts[3] = perpetualMintViewSupraBlastFacetCut;
    }
}
