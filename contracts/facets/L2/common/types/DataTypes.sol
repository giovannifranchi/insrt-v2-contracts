// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { AssetType } from "../../../../enums/AssetType.sol";

/// @dev DataTypes.sol defines the common L2 struct data types used in the PerpetualMintStorage layout

/// @dev Represents owner data specific to a collection.
/// @dev Unified data structure for representing collection owner data for any type of asset.
struct CollectionOwnerData {
    /// @dev Total number of active tokens associated with the owner of a given collection.
    uint256 activeTokens;
    /// @dev Accumulated earnings for the owner of a given collection.
    uint256 earnings;
    /// @dev Total number of inactive tokens associated with the owner of a given collection.
    uint256 inactiveTokens;
    /// @dev Offset applied to the base earnings multiplier for the owner of a given collection.
    uint256 multiplierOffset;
    /// @dev Cumulative risk for the owner of a given collection.
    uint256 totalRisk;
}

/// @dev Represents data specific to a collection.
/// @dev Unified data structure for representing collection data for any type of asset.
struct CollectionData {
    /// @dev Specifies the type of asset for a collection.
    AssetType assetType;
    /// @dev Total number of active tokens present in the collection.
    uint256 activeTokens;
    /// @dev The base multiplier used for earnings calculation in the collection.
    uint256 baseMultiplier;
    /// @dev Accumulated earnings for the entire collection.
    uint256 earnings;
    /// @dev The value of earnings when the collection totalRisk was last updated.
    uint256 lastEarnings;
    /// @dev Total risk associated with the collection.
    uint256 totalRisk;
    /// @dev Mapping from a token ID to its specific data.
    mapping(uint256 => TokenData) tokens;
    /// @dev Set of active token IDs present in the collection.
    EnumerableSet.UintSet activeTokenIds;
}

/// @dev Represents data specific to an ERC1155 token.
struct ERC1155TokenData {
    /// @dev Set of addresses that own this specific token ID.
    EnumerableSet.AddressSet owners;
    /// @dev Mapping from an owner's adress to their specific data for this token.
    mapping(address owner => ERC1155TokenOwnerData) tokenOwnerData;
    /// @dev Total risk associated with the token.
    uint256 totalRisk;
}

/// @dev Represents data specific to an owner of a given ERC1155 token.
struct ERC1155TokenOwnerData {
    /// @dev Total amount of active tokens held by the owner of a given ERC1155 token.
    uint256 activeTokenAmount;
    /// @dev Total amount of inactive tokens held by the owner of a given ERC1155 token.
    uint256 inactiveTokenAmount;
    /// @dev Risk value set for the token by the owner of a given ERC1155 token.
    uint256 risk;
}

/// @dev Represents data specific to an ERC721 token.
struct ERC721TokenData {
    /// @dev The address designated as the owner of the escrowed ERC721 token.
    address owner;
    /// @dev Risk value set for the token.
    uint256 risk;
}

/// @dev Represents the unified data structure for representing token data for any type of asset.
struct TokenData {
    /// @dev Data specific to ERC1155 tokens.
    ERC1155TokenData erc1155Token;
    /// @dev Data specific to ERC721 tokens.
    ERC721TokenData erc721Token;
}

/// @dev Encapsulates variables related to Chainlink VRF
/// @dev see: https://docs.chain.link/vrf/v2/subscription#set-up-your-contract-and-request
struct VRFConfig {
    /// @dev Chainlink identifier for prioritizing transactions
    /// different keyhashes have different gas prices thus different priorities
    bytes32 keyHash; /// slot 0
    /// @dev id of Chainlink subscription to VRF for PerpetualMint contract
    uint64 subscriptionId; /// slot 1
    /// @dev maximum amount of gas a user is willing to pay for completing the callback VRF function
    uint32 callbackGasLimit;
    /// @dev number of block confirmations the VRF service will wait to respond
    uint16 minConfirmations;
}
