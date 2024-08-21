// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ITokenProxy } from "../../../contracts/diamonds/Token/ITokenProxy.sol";
import { TokenBridge } from "../../../contracts/facets/Token/TokenBridge.sol";
import { ITokenBridge } from "../../../contracts/facets/Token/ITokenBridge.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { Script, console } from "forge-std/Script.sol";

import { IToken } from "../../../contracts/facets/Token/IToken.sol";

/// @title ConfigureTokenBridgeFacet
/// @dev deploys the TokenBridge facet and cuts it onto the TokenProxy diamond
contract ConfigureTokenBridgeFacet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
        address gateway = vm.envAddress("GATEWAYWAY_ADDRESS");
        address gasService = vm.envAddress("GAS_SERVICE_ADDRESS");
        address payable tokenProxyAddress = payable(
            vm.envAddress("TOKEN_PROXY_ADDRESS")
        );

        vm.startBroadcast(deployerPrivateKey);

        // deploy TokenBridge facet
        ITokenBridge tokenBridgeFacet = new TokenBridge(gateway, gasService);
        console.log("TokenBridge Facet Address: ", address(tokenBridgeFacet));

        // getfacet cuts from TokenBridge facet
        ITokenProxy.FacetCut[] memory tokenBridgeFacetCut = getTokenBridgeFacet(
            address(tokenBridgeFacet)
        );

        // cut TokenBridge facet onto TokenProxy diamond
        ITokenProxy(tokenProxyAddress).diamondCut(
            tokenBridgeFacetCut,
            address(0),
            ""
        );

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting TokenBridge facet into TokenProxy
    /// @param facetAddress address of TokenBridge facet
    function getTokenBridgeFacet(
        address facetAddress
    ) internal pure returns (ITokenProxy.FacetCut[] memory) {
        // map the TokenBridge function selectors to their respective interfaces
        bytes4[] memory tokenBridgeFunctionSelectors = new bytes4[](7);

        tokenBridgeFunctionSelectors[0] = ITokenBridge.bridgeToken.selector;
        tokenBridgeFunctionSelectors[1] = ITokenBridge
            .enableSupportedChains
            .selector;
        tokenBridgeFunctionSelectors[2] = ITokenBridge
            .disableSupportedChains
            .selector;
        tokenBridgeFunctionSelectors[3] = ITokenBridge.getDestinationAddress.selector;
        tokenBridgeFunctionSelectors[4] = IAxelarExecutable.execute.selector;
        tokenBridgeFunctionSelectors[5] = IAxelarExecutable
            .executeWithToken
            .selector;
        tokenBridgeFunctionSelectors[6] = IAxelarExecutable.gateway.selector;

        ITokenProxy.FacetCut
            memory tokenBridgeFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: tokenBridgeFunctionSelectors
            });

        ITokenProxy.FacetCut[] memory facetCuts = new ITokenProxy.FacetCut[](1);
        facetCuts[0] = tokenBridgeFacetCut;
        return facetCuts;
    }
}
