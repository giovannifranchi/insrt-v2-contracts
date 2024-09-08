// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../../../contracts/facets/Token/TokenBridge.sol";
import { ITokenBridge } from "../../../contracts/facets/Token/ITokenBridge.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

/// @title TokenBridgeHelper
/// @dev Test helping contract for setting up TokenBridge facet for diamond cutting and testing
contract TokenBridgeHelper {
    TokenBridge public tokenBridgeImplmentation;

    constructor(address gateway, address gasService) {
        tokenBridgeImplmentation = new TokenBridge(gateway, gasService);
    }

    /// @dev provides the facet cuts for cutting TokenBridge facet into TokenProxy diamond
    function getAxelarBridgeFacetCuts()
        public
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        // map the TokenBridge function selectors to their respective interfaces
        bytes4[] memory tokenBridgeFunctionSelectors = new bytes4[](12);

        tokenBridgeFunctionSelectors[0] = ITokenBridge.bridgeToken.selector;
        tokenBridgeFunctionSelectors[1] = ITokenBridge
            .enableSupportedChains
            .selector;
        tokenBridgeFunctionSelectors[2] = ITokenBridge
            .disableSupportedChains
            .selector;
        tokenBridgeFunctionSelectors[3] = ITokenBridge
            .getDestinationAddress
            .selector;
        tokenBridgeFunctionSelectors[4] = ITokenBridge
            .enableAddressLength
            .selector;
        tokenBridgeFunctionSelectors[5] = ITokenBridge
            .disableAddressLength
            .selector;
        tokenBridgeFunctionSelectors[6] = ITokenBridge
            .batchEnableAddressLength
            .selector;
        tokenBridgeFunctionSelectors[7] = ITokenBridge
            .batchDisableAddressLength
            .selector;
        tokenBridgeFunctionSelectors[8] = ITokenBridge.getGasService.selector;
        tokenBridgeFunctionSelectors[9] = IAxelarExecutable.execute.selector;
        tokenBridgeFunctionSelectors[10] = IAxelarExecutable
            .executeWithToken
            .selector;
        tokenBridgeFunctionSelectors[11] = IAxelarExecutable.gateway.selector;

        ISolidStateDiamond.FacetCut
            memory axelarBridgeFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(tokenBridgeImplmentation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: tokenBridgeFunctionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);
        facetCuts[0] = axelarBridgeFacetCut;

        return facetCuts;
    }
}
