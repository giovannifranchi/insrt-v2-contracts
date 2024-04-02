// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial RC1155MetadataExtensionInternal interface needed by internal functions
 */
interface IERC1155MetadataExtensionInternal {
    /// @notice thrown when not enough token values are found to unset for a given token ID
    /// during token transfers
    error NotEnoughTokenValuesFoundToUnset();

    /// @notice emitted when new token values are set
    /// @param owner owner of the token
    /// @param tokenId token ID
    /// @param amount number of tokens values were set for
    /// @param tokenValue value set for each token
    event TokenValuesSet(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 tokenValue
    );

    /// @notice emitted when token values are unset
    /// @param owner owner of the token
    /// @param tokenId token ID
    /// @param amount number of tokens values were unset for
    /// @param tokenValue value unset for each token
    event TokenValuesUnset(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 tokenValue
    );
}
