// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { TokenTest } from "./Token.t.sol";
import { TokenBridgeHelper } from "./TokenBridgeHelper.t.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

contract TokenBridge is TokenTest {
    TokenBridgeHelper public tokenBridgeHelper;

    function setUp() public virtual override {
        super.setUp();
    }

    function initTokenBridge(address gateway, address gasService) internal {
        tokenBridgeHelper = new TokenBridgeHelper(gateway, gasService);

        ISolidStateDiamond.FacetCut[] memory facetCuts = tokenBridgeHelper
            .getAxelarBridgeFacetCuts();

        tokenProxy.diamondCut(facetCuts, address(0), "");
    }
}
