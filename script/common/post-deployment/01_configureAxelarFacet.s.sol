// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ITokenProxy } from "../../../contracts/diamonds/Token/ITokenProxy.sol";
import { AxelarBridge } from "../../../contracts/facets/AxelarBridge/AxelarBridge.sol";
import { IAxelarBridge } from "../../../contracts/facets/AxelarBridge/IAxelarBridge.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { Script, console } from "forge-std/Script.sol";

import { IToken } from "../../../contracts/facets/Token/IToken.sol";

/// @title ConfigureAxelarFacet
/// @dev deploys the AxelarBridge facet and cuts it onto the TokenProxy diamond
contract ConfigureAxelarFacet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address gateway = vm.envAddress("GATEWAYWAY_ADDRESS");
        address gasService = vm.envAddress("GAS_SERVICE_ADDRESS");
        address payable tokenProxyAddress = payable(
            vm.envAddress("TOKEN_PROXY_ADDRESS")
        );

        vm.startBroadcast(deployerPrivateKey);

        // deploy AxelarBridge facet
        AxelarBridge axelarBridgeFacet = new AxelarBridge(gateway, gasService);
        console.log("AxelarBridge Facet Address: ", address(axelarBridgeFacet));

        // getfacet cuts from AxelarBridge facet
        ITokenProxy.FacetCut[]
            memory axelarBridgeFacetCuts = getAxelarBridgeFacetCuts(
                address(axelarBridgeFacet)
            );

        // cut AxelarBridge facet onto TokenProxy diamond
        ITokenProxy(tokenProxyAddress).diamondCut(
            axelarBridgeFacetCuts,
            address(0),
            ""
        );

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting AxelarBridge facet into TokenProxy
    /// @param facetAddress address of AxelarBridge facet
    function getAxelarBridgeFacetCuts(
        address facetAddress
    ) internal pure returns (ITokenProxy.FacetCut[] memory) {
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

        ITokenProxy.FacetCut
            memory axelarBridgeFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: axelarBridgeFunctionSelectors
            });

        ITokenProxy.FacetCut[] memory facetCuts = new ITokenProxy.FacetCut[](1);
        facetCuts[0] = axelarBridgeFacetCut;
        return facetCuts;
    }
}
