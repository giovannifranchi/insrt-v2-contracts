// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintHarnessSupra } from "./IPerpetualMintHarness.sol";
import { PerpetualMintHarness } from "../PerpetualMintHarness.t.sol";
import { CollectionData, PerpetualMintStorage as Storage } from "../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintHarnessSupra
/// @dev exposes PerpetualMintSupra external & internal functions for testing
contract PerpetualMintHarnessSupra is
    IPerpetualMintHarnessSupra,
    PerpetualMintHarness
{
    /// @dev number of words used in mints for $MINT
    uint8 private constant ONE_WORD = 1;

    /// @dev number of words used in mints for collections
    uint8 private constant TWO_WORDS = 2;

    constructor(address vrf) PerpetualMintHarness(vrf) {}

    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintForMintWithEthSupra(
            msg.sender,
            referrer,
            uint8(numberOfMints),
            ONE_WORD
        );
    }

    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external override whenNotPaused {
        _attemptBatchMintForMintWithMintSupra(
            msg.sender,
            referrer,
            pricePerMint,
            uint8(numberOfMints),
            ONE_WORD
        );
    }

    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints,
        uint256 collectionFloorPrice
    ) external payable override whenNotPaused {
        _attemptBatchMintWithEthSupra(
            msg.sender,
            collection,
            referrer,
            uint8(numberOfMints),
            TWO_WORDS,
            collectionFloorPrice
        );
    }

    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external whenNotPaused {
        _attemptBatchMintWithMintSupra(
            msg.sender,
            collection,
            referrer,
            pricePerMint,
            uint8(numberOfMints),
            TWO_WORDS,
            0
        );
    }

    function exposed_requestRandomWordsSupra(
        address minter,
        address collection,
        uint256 mintPriceAdjustmentFactor,
        uint256 collectionFloorPrice,
        uint8 numWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            collectionFloorPrice,
            numWords
        );
    }
}
