// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ERC1155MetadataExtensionStorage } from "./ERC1155MetadataExtensionStorage.sol";
import { IERC1155MetadataExtensionInternal } from "./IERC1155MetadataExtensionInternal.sol";

/// @title ERC1155MetadataExtensionInternal
/// @dev ERC1155MetadataExtension internal functions
abstract contract ERC1155MetadataExtensionInternal is
    IERC1155MetadataExtensionInternal
{
    /// @notice Retrieves token values for a given owner and token ID
    /// @param owner The owner of the tokens
    /// @param tokenId The token ID for which values are retrieved
    /// @return tokenValues An array of uint256 representing the values of each token
    function _getTokenValues(
        address owner,
        uint256 tokenId
    ) internal view returns (uint256[] memory tokenValues) {
        tokenValues = ERC1155MetadataExtensionStorage.layout().tokenValues[
            owner
        ][tokenId];
    }

    /// @notice reads the ERC1155 collection name
    /// @return name ERC1155 collection name
    function _name() internal view returns (string memory name) {
        name = ERC1155MetadataExtensionStorage.layout().name;
    }

    /// @notice sets a new name for the ERC1155 collection
    /// @param name name to set
    function _setName(string memory name) internal {
        ERC1155MetadataExtensionStorage.layout().name = name;
    }

    /// @notice sets a new symbol for the ERC1155 collection
    /// @param symbol symbol to set
    function _setSymbol(string memory symbol) internal {
        ERC1155MetadataExtensionStorage.layout().symbol = symbol;
    }

    /// @notice sets new token values for a given owner, token ID, & amount of tokens
    /// @param owner owner of the token
    /// @param tokenId token ID
    /// @param amount number of tokens to set values for
    /// @param tokenValue value to set for each token
    function _setTokenValues(
        address owner,
        uint256 tokenId,
        uint256 amount,
        uint256 tokenValue
    ) internal {
        uint256[] storage tokenValues = ERC1155MetadataExtensionStorage
            .layout()
            .tokenValues[owner][tokenId];

        for (uint256 i = 0; i < amount; ++i) {
            tokenValues.push(tokenValue);
        }

        emit TokenValuesSet(owner, tokenId, amount, tokenValue);
    }

    /// @notice reads the ERC1155 collection symbol
    /// @return symbol ERC1155 collection symbol
    function _symbol() internal view returns (string memory symbol) {
        symbol = ERC1155MetadataExtensionStorage.layout().symbol;
    }

    /// @notice unsets token values for a given owner, token ID, & amount of tokens
    /// @param owner owner of the token
    /// @param tokenId token ID
    /// @param amount number of tokens to unset values for
    /// @param tokenValue value to unset for each token
    function _unsetTokenValues(
        address owner,
        uint256 tokenId,
        uint256 amount,
        uint256 tokenValue
    ) internal {
        uint256[] storage tokenValues = ERC1155MetadataExtensionStorage
            .layout()
            .tokenValues[owner][tokenId];

        uint256 foundValues;

        for (
            uint256 i = 0;
            i < tokenValues.length && foundValues < amount;
            ++i
        ) {
            if (tokenValues[i] == tokenValue) {
                // To remove a value, we can swap it with the last one and then pop from the array to avoid gaps
                tokenValues[i] = tokenValues[tokenValues.length - 1];
                tokenValues.pop();
                ++foundValues;
            }
        }

        if (foundValues != amount) {
            revert NotEnoughTokenValuesFoundToUnset();
        }

        emit TokenValuesUnset(owner, tokenId, amount, tokenValue);
    }
}
