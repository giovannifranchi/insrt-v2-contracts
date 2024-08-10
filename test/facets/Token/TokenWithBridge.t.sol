// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { TokenTest } from "./Token.t.sol";
import { TokenAxelarHelper } from "./TokenAxelarHelper.t.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

contract TokenWithBridge is TokenTest {
    TokenAxelarHelper public tokenAxelarHelper;

    function setUp() public virtual override {
        super.setUp();
    }

    function initTokenWithBridge(
        address _gateway,
        address _gasService
    ) internal {
        tokenAxelarHelper = new TokenAxelarHelper(_gateway, _gasService);

        ISolidStateDiamond.FacetCut[] memory facetCuts = tokenAxelarHelper
            .getAxelarBridgeFacetCuts();

        tokenProxy.diamondCut(facetCuts, address(0), "");
    }
}
