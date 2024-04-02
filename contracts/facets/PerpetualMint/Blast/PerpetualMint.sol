// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMint } from "../IPerpetualMint.sol";
import { PerpetualMint } from "../PerpetualMint.sol";

/// @title PerpetualMintBlast
/// @dev Blast-specific PerpetualMint facet
contract PerpetualMintBlast is IPerpetualMint, PerpetualMint {
    constructor(address vrf) PerpetualMint(vrf) {}

    /// @notice VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from VRF coordinator
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWordsBlast(requestId, randomWords);
    }
}
