// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintHarness, RequestData } from "../IPerpetualMintHarness.sol";

/// @title IPerpetualMintHarnessSupra
/// @dev Extended Supra-specific interface for the PerpetualMintHarness contract
interface IPerpetualMintHarnessSupra is IPerpetualMintHarness {
    /// @dev exposes _requestRandomWordsSupra
    function exposed_requestRandomWordsSupra(
        address minter,
        address collection,
        uint256 mintPriceAdjustmentFactor,
        uint256 collectionFloorPrice,
        uint8 numWords
    ) external;
}
