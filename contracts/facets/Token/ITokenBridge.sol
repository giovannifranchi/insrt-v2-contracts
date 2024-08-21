// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

/// @title ITokenBridge
/// @notice it is the interface for the Token Bridge
/// @dev it contains all the external functions of the TokenBridge
interface ITokenBridge is IAxelarExecutable {
    /// @notice it enables to add a supported chain
    /// @param destinationChain the destination chain (right format needs to be picked from https://docs.axelar.dev/dev/reference/mainnet-contract-addresses)
    /// @param destinationAddress the destination address of the specular deployed contract
    /// @dev only the owner can call this function
    /// @dev it emits a SupportedChainsEnabled event
    /// @dev it allows to change the destination address of an already suppoerted chain
    function enableSupportedChains(
        string calldata destinationChain,
        string calldata destinationAddress
    ) external;

    /// @notice it disables a supported chain
    /// @param destinationChain the destination chain
    /// @dev only the owner can call this function
    /// @dev it emits a SupportedChainsDisabled event
    function disableSupportedChains(string calldata destinationChain) external;

    /// @notice it bridges a token from the source chain to the destination chain
    /// @param destinationChain the destination chain
    /// @param amount the amount of token to bridge
    /// @dev it emits a ToeknBridgeInitilised event
    /// @dev it is payable because it needs to receive native tokens for gas functionalities
    /// @dev it can transfer the entire balance of an account if the amount is set to type(uint256).max
    function bridgeToken(
        string calldata destinationChain,
        uint256 amount
    ) external payable;

    /// @notice it returns the destination address of a supported chain
    /// @param destinationChain the destination chain
    /// @return destinationAddress
    function supportedChains(
        string calldata destinationChain
    ) external view returns (string memory destinationAddress);
}
