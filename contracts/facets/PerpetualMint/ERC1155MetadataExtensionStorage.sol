// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ERC1155MetadataExtensionStorage
library ERC1155MetadataExtensionStorage {
    struct Layout {
        /// @dev ERC1155 collection name
        string name;
        /// @dev ERC1155 collection symbol
        string symbol;
        /// @dev mapping of unique token values for each token ID, indexed by owner and token ID
        mapping(address owner => mapping(uint256 tokenId => uint256[] tokenValues)) tokenValues;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.ERC1155MetadataExtensionStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}
