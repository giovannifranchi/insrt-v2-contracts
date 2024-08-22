// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IAxelarGateway } from "@axelar/interfaces/IAxelarGateway.sol";

import { AxelarExecutable } from "@axelar/executable/AxelarExecutable.sol";

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import { ITokenBridge } from "./ITokenBridge.sol";

import { TokenBridgeInternal } from "./TokenBridgeInternal.sol";

/// @title TokenBridge
/// @notice it is the main contract for the Token Bridge
/// @dev it contains all the external functions of TokenBridge
contract TokenBridge is
    OwnableInternal,
    AxelarExecutable,
    TokenBridgeInternal,
    ITokenBridge
{
    modifier onlySupportedChains(string calldata destinationChain) {
        if (!_isDestinationChainSupported(destinationChain))
            revert TokenBridge__UnsupportedChain();
        _;
    }

    constructor(
        address gateway,
        address gasService
    ) AxelarExecutable(gateway) TokenBridgeInternal(gasService) {}

    /// @inheritdoc ITokenBridge
    function enableSupportedChains(
        string calldata destinationChain,
        string calldata destinationAddress
    ) external onlyOwner {
        _enableSupportedChains(destinationChain, destinationAddress);
    }

    /// @inheritdoc ITokenBridge
    function disableSupportedChains(
        string calldata destinationChain
    ) external onlyOwner {
        _disableSupportedChains(destinationChain);
    }

    /// @inheritdoc ITokenBridge
    function getDestinationAddress(
        string calldata destinationChain
    ) public view returns (string memory destinationAddress) {
        return destinationAddress = _getDestinationAddress(destinationChain);
    }

    /// @inheritdoc ITokenBridge
    function bridgeToken(
        string calldata destinationChain,
        uint256 amount
    ) external payable onlySupportedChains(destinationChain) {
        _bridgeToken(destinationChain, amount, gateway);
    }

    /// @inheritdoc ITokenBridge
    function enableAddressLength(uint256 length) external onlyOwner {
        _enableAddressLength(length);
    }

    /// @inheritdoc ITokenBridge
    function disableAddressLength(uint256 length) external onlyOwner {
        _disableAddressLength(length);
    }

    /// @inheritdoc ITokenBridge
    function batchEnableAddressLength(uint256 mask) external onlyOwner {
        _batchEnableAddressLength(mask);
    }

    /// @inheritdoc ITokenBridge
    function batchDisableAddressLength(uint256 mask) external onlyOwner {
        _batchDisableAddressLength(mask);
    }

    /// @inheritdoc AxelarExecutable
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        _execute(payload, sourceChain, sourceAddress);
    }
}
