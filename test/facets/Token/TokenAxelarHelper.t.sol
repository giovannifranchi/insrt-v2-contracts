// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { AxelarBridge } from "../../../contracts/facets/AxelarBridge/AxelarBridge.sol";
import { IAxelarBridge } from "../../../contracts/facets/AxelarBridge/IAxelarBridge.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

contract TokenAxelarHelper {
    AxelarBridge public axelarBridgeImplementation;

    constructor(address _gateway, address _gasService) {
        axelarBridgeImplementation = new AxelarBridge(_gateway, _gasService);
    }

    /// @dev provides the facet cuts for cutting AxelarBridge facet into TokenProxy diamond
    function getAxelarBridgeFacetCuts()
        public
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        // map the AxelarBridge function selectors to their respective interfaces
        bytes4[] memory axelarBridgeFunctionSelectors = new bytes4[](7);

        axelarBridgeFunctionSelectors[0] = IAxelarBridge.bridgeToken.selector;
        axelarBridgeFunctionSelectors[1] = IAxelarBridge
            .enableSupportedChains
            .selector;
        axelarBridgeFunctionSelectors[2] = IAxelarBridge
            .disableSupportedChains
            .selector;
        axelarBridgeFunctionSelectors[3] = IAxelarBridge
            .supportedChains
            .selector;
        axelarBridgeFunctionSelectors[4] = IAxelarExecutable.execute.selector;
        axelarBridgeFunctionSelectors[5] = IAxelarExecutable
            .executeWithToken
            .selector;
        axelarBridgeFunctionSelectors[6] = IAxelarExecutable.gateway.selector;

        ISolidStateDiamond.FacetCut
            memory axelarBridgeFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(axelarBridgeImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: axelarBridgeFunctionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);
        facetCuts[0] = axelarBridgeFacetCut;

        return facetCuts;
    }
}
