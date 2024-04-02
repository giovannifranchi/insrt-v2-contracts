// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";

import { IPerpetualMintHarnessSupraBlast } from "./IPerpetualMintHarness.sol";
import { IPerpetualMintHarnessBlast } from "../IPerpetualMintHarness.sol";
import { PerpetualMintHarness } from "../../PerpetualMintHarness.t.sol";
import { IPerpetualMintHarnessSupra } from "../../Supra/IPerpetualMintHarness.sol";
import { PerpetualMint } from "../../../../../contracts/facets/PerpetualMint/PerpetualMint.sol";
import { CollectionData, MintTokenTiersData, RequestData, PerpetualMintStorage as Storage, TiersData } from "../../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintHarnessSupraBlast
/// @dev exposes PerpetualMintSupraBlast external & internal functions for testing
contract PerpetualMintHarnessSupraBlast is
    IPerpetualMintHarnessSupraBlast,
    PerpetualMintHarness
{
    /// @dev number of words used in mints for $MINT
    uint8 private constant TWO_WORDS = 2;

    /// @dev number of words used in mints for collections
    uint8 private constant THREE_WORDS = 3;

    constructor(address vrf) PerpetualMintHarness(vrf) {}

    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable override whenNotPaused {
        _attemptBatchMintForMintWithEthSupra(
            msg.sender,
            referrer,
            uint8(numberOfMints),
            TWO_WORDS
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
            TWO_WORDS
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
            THREE_WORDS,
            collectionFloorPrice
        );
    }

    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint256 collectionFloorPrice,
        uint32 numberOfMints
    ) external override whenNotPaused {
        _attemptBatchMintWithMintSupra(
            msg.sender,
            collection,
            referrer,
            pricePerMint,
            collectionFloorPrice,
            uint8(numberOfMints),
            THREE_WORDS
        );
    }

    /// @inheritdoc IPerpetualMintHarnessBlast
    function exposed_resolveMintsBlast(
        RequestData calldata request,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[
            request.collection
        ];

        TiersData memory tiersData = l.tiers;

        _resolveMintsBlast(
            l.mintToken,
            collectionData,
            request,
            tiersData,
            randomWords,
            _ethToMintRatio(l)
        );
    }

    /// @inheritdoc IPerpetualMintHarnessBlast
    function exposed_resolveMintsForMintBlast(
        address minter,
        uint256 mintPriceAdjustmentFactor,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        // for now, mints for $MINT are treated as address(0) collections
        address collection = address(0);

        CollectionData storage collectionData = l.collections[collection];

        MintTokenTiersData memory mintTokenTiersData = l.mintTokenTiers;

        _resolveMintsForMintBlast(
            l.mintToken,
            _collectionMintMultiplier(collectionData),
            _collectionMintPrice(collectionData),
            mintPriceAdjustmentFactor,
            mintTokenTiersData,
            minter,
            randomWords,
            _ethToMintRatio(l)
        );
    }

    /// @inheritdoc IPerpetualMintHarnessSupra
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

    function setBlastYieldRisk(uint32 risk) external onlyOwner {
        _setBlastYieldRisk(risk);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override(PerpetualMint, VRFConsumerBaseV2) {
        _fulfillRandomWordsBlast(requestId, randomWords);
    }
}
