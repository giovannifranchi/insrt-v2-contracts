// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ERC165Base } from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import { ERC1155Base } from "@solidstate/contracts/token/ERC1155/base/ERC1155Base.sol";
import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { ERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155Metadata.sol";

import { ERC1155MetadataExtension } from "./ERC1155MetadataExtension.sol";
import { IPerpetualMintBase } from "./IPerpetualMintBase.sol";
import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";

/// @title PerpetualMintBase
/// @dev PerpetualMintBase facet containing all protocol-specific externally called functions
contract PerpetualMintBase is
    ERC1155Base,
    ERC1155Metadata,
    ERC1155MetadataExtension,
    ERC165Base,
    IPerpetualMintBase,
    PerpetualMintInternal
{
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMintBase
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 onERC1155ReceivedSelector) {
        onERC1155ReceivedSelector = this.onERC1155Received.selector;
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWords(requestId, randomWords);
    }

    /// @notice overrides _beforeTokenTransfer hook to enforce token value data payload requirements
    /// @param operator address which initiated the transfer
    /// @param from address from which the tokens are transferred
    /// @param to address to which the tokens are transferred
    /// @param ids array of token ids
    /// @param amounts array of token amounts
    /// @param data data payload (expected to contain a uint256 array of token values)
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155BaseInternal, PerpetualMintInternal) {
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
