// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

/// @title IAxelarBridge
/// @notice it is the interface for the Axelar Bridge
/// @dev it contains all the external functions of the Axelar Bridge
interface IAxelarBridge is IAxelarExecutable {
    /// @notice it is thown when the chain is not supported
    error AxelarBridge__UnsupportedChain();

    /// @notice it is thown when the chain is invalid
    error AxelarBridge__InvalidChain();

    /// @notice it is thown when the address is invalid
    error AxelarBridge__InvalidAddress();

    /// @notice it is thown when the chain is not yet supported
    error AxelarBridge__NotYetSupportedChain();

    /// @notice it is thown when the amount is zero
    error AxelarBridge__NoZeroAmount();

    /// @notice it is thown when the balance is insufficient
    error AxelarBridge__InsufficientBalance();

    error AxelarBridge__NotEnoughGas();

    /// @notice it is emitted when the chain is enabled
    event SupportedChainsEnabled(
        string indexed destinationChain,
        string indexed destinationAddress
    );

    /// @notice it is emitted when the chain is disabled
    event SupportedChainsDisabled(string indexed destinationChain);

    /// @notice it is emitted when the token has started its bridge from the source chain
    event ToeknBridgeInitilised(
        string indexed destinationChain,
        string indexed destinationAddress,
        uint256 indexed amount
    );

    /// @notice it is emitted when the token has finalized its bridge to the destination chain
    event TokenBridgeFinalized(
        string indexed destinationChain,
        string destinationAddress,
        uint256 indexed amount,
        address indexed receiver
    );

    /// @notice it enables to add a supported chain
    /// @param _destinationChain the destination chain (right format needs to be picked from https://docs.axelar.dev/dev/reference/mainnet-contract-addresses)
    /// @param _destinationAddress the destination address of the specular deployed contract
    /// @dev only the owner can call this function
    /// @dev it emits a SupportedChainsEnabled event
    /// @dev it allows to change the destination address of an already suppoerted chain
    function enableSupportedChains(
        string calldata _destinationChain,
        string calldata _destinationAddress
    ) external;

    /// @notice it disables a supported chain
    /// @param _destinationChain the destination chain
    /// @dev only the owner can call this function
    /// @dev it emits a SupportedChainsDisabled event
    function disableSupportedChains(string calldata _destinationChain) external;

    /// @notice it bridges a token from the source chain to the destination chain
    /// @param _destinationChain the destination chain
    /// @param amount the amount of token to bridge
    /// @dev it emits a ToeknBridgeInitilised event
    /// @dev it is payable because it needs to receive native tokens for gas functionalities
    /// @dev it can transfer the entire balance of an account if the amount is set to type(uint256).max
    function bridgeToken(
        string calldata _destinationChain,
        uint256 amount
    ) external payable;

    /// @notice it returns the destination address of a supported chain
    /// @param _destinationChain the destination chain
    /// @return the destination address
    function supportedChains(
        string calldata _destinationChain
    ) external view returns (string memory);
}
