// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { VRFConsumerBaseV2Mock } from "../../mocks/VRFConsumerBaseV2Mock.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";
import { CollectionData, MintTokenTiersData, RequestData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintHarness
/// @dev exposes PerpetualMint external & internal functions for testing
contract PerpetualMintHarness is
    IPerpetualMintHarness,
    PerpetualMint,
    Test,
    VRFConsumerBaseV2Mock
{
    using EnumerableSet for EnumerableSet.UintSet;

    constructor(address vrf) PerpetualMint(vrf) {}

    /// @inheritdoc IPerpetualMintHarness
    function exposed_enforceBasis(uint32 value) external pure {
        _enforceBasis(value, _BASIS());
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_normalizeValue(
        uint256 value,
        uint32 basis
    ) external pure returns (uint256 normalizedValue) {
        normalizedValue = _normalizeValue(value, basis);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_pendingRequestsAdd(
        address collection,
        uint256 requestId
    ) external {
        Storage.layout().collections[collection].pendingRequests.add(requestId);
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_pendingRequestsAt(
        address collection,
        uint256 index
    ) external view returns (uint256 requestId) {
        requestId = Storage.layout().collections[collection].pendingRequests.at(
            index
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_pendingRequestsLength(
        address collection
    ) external view returns (uint256 length) {
        length = Storage
            .layout()
            .collections[collection]
            .pendingRequests
            .length();
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_requestRandomWords(
        address minter,
        address collection,
        uint256 mintEarningsFeePerSpin,
        uint256 mintPriceAdjustmentFactor,
        uint256 prizeValueInWei,
        uint32 numWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            mintEarningsFeePerSpin,
            mintPriceAdjustmentFactor,
            prizeValueInWei,
            numWords
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_requestRandomWordsSupra(
        address minter,
        address collection,
        uint256 mintEarningsFeePerSpin,
        uint256 mintPriceAdjustmentFactor,
        uint256 prizeValueInWei,
        uint8 numWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            collection,
            mintEarningsFeePerSpin,
            mintPriceAdjustmentFactor,
            prizeValueInWei,
            numWords
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_requests(
        uint256 requestId
    )
        external
        view
        returns (
            address minter,
            address collection,
            uint256 mintEarningsFeePerSpin,
            uint256 mintPriceAdjustmentFactor,
            uint256 prizeValueInWei
        )
    {
        RequestData storage request = Storage.layout().requests[requestId];

        (
            minter,
            collection,
            mintEarningsFeePerSpin,
            mintPriceAdjustmentFactor,
            prizeValueInWei
        ) = (
            request.minter,
            request.collection,
            request.mintEarningsFeePerSpin,
            request.mintPriceAdjustmentFactor,
            request.prizeValueInWei
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_resolveMints(
        address minter,
        address collection,
        uint256 mintPriceAdjustmentFactor,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        TiersData memory tiersData = l.tiers;

        _resolveMints(
            l.mintToken,
            collectionData,
            mintPriceAdjustmentFactor,
            tiersData,
            minter,
            collection,
            randomWords,
            _ethToMintRatio(l)
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_resolveMintsForEth(
        RequestData calldata request,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[
            request.collection
        ];

        _resolveMintsForEth(
            l,
            request,
            _collectionMintMultiplier(collectionData),
            _collectionMintPrice(collectionData),
            randomWords,
            _ethToMintRatio(l)
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function exposed_resolveMintsForMint(
        address minter,
        uint256 mintPriceAdjustmentFactor,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        // for now, mints for $MINT are treated as address(0) collections
        address collection = address(0);

        CollectionData storage collectionData = l.collections[collection];

        MintTokenTiersData memory mintTokenTiersData = l.mintTokenTiers;

        _resolveMintsForMint(
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

    /// @inheritdoc IPerpetualMintHarness
    function mintReceipts(address collection, uint256 receiptAmount) external {
        _safeMint(
            msg.sender,
            uint256(bytes32(abi.encode(collection))),
            receiptAmount,
            ""
        );
    }

    /// @inheritdoc IPerpetualMintHarness
    function setConsolationFees(uint256 amount) external {
        Storage.layout().consolationFees = amount;
    }

    /// @inheritdoc IPerpetualMintHarness
    function setMintEarnings(uint256 amount) external {
        Storage.layout().mintEarnings = amount;
    }

    /// @inheritdoc IPerpetualMintHarness
    function setProtocolFees(uint256 amount) external {
        Storage.layout().protocolFees = amount;
    }

    /// @inheritdoc IPerpetualMintHarness
    function setRequests(
        uint256 requestId,
        address minter,
        address collection,
        uint256 mintEarningsFeePerSpin,
        uint256 mintPriceAdjustmentFactor,
        uint256 prizeValueInWei
    ) external {
        Storage.layout().requests[requestId] = RequestData({
            collection: collection,
            minter: minter,
            mintEarningsFeePerSpin: mintEarningsFeePerSpin,
            mintPriceAdjustmentFactor: mintPriceAdjustmentFactor,
            prizeValueInWei: prizeValueInWei
        });
    }
}
