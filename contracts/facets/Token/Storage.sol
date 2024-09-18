// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { AccrualData } from "./types/DataTypes.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/// @title TokenStorage
/// @dev defines storage layout for the Token facet
library TokenStorage {
    struct Layout {
        /// @dev ratio of distributionSupply to totalSupply
        uint256 globalRatio;
        /// @dev number of tokens held for distribution to token holders
        uint256 distributionSupply;
        /// @dev number of tokens held for airdrop dispersion
        uint256 airdropSupply;
        /// @dev fraction of tokens to be reserved for distribution to token holders in basis points
        uint32 distributionFractionBP;
        /// @dev information related to Token accruals for an account
        mapping(address account => AccrualData data) accrualData;
        /// @dev set of contracts which are allowed to call the mint function
        EnumerableSet.AddressSet mintingContracts;
        /// @notice it stores the supported chains, the key is the destination chain and the value is the destination address
        /// @dev it uses strings to store addresses in order to support EVM and non-EVM chain address types, it is an Axelar standard
        mapping(string supportedChain => string targetAddress) supportedChains;
        /// @dev it stores the allowed address length
        /// @dev it is a bitmap, each bit represents a length, if the bit is set to 1, the length is allowed
        uint256 allowedAddressLengthBitMap;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.MintToken");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
