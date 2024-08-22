// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ITokenBridgeInternal
/// @notice it is the interface for the Token Bridge Internal
/// @dev it contains all the errors and events of the TokenBridgeInternal
interface ITokenBridgeInternal {
    /// @notice it is thown when the chain is not supported
    error TokenBridge__UnsupportedChain();

    /// @notice it is thown when the chain is invalid
    error TokenBridge__InvalidChain();

    /// @notice it is thown when the address is invalid
    error TokenBridge__InvalidAddress();

    /// @notice it is thown when the address length is invalid
    error TokenBridge__InvalidAddressLength();

    /// @notice it is thown when the addresses lengths provided to the _batchEnableAddressLength and _batchDisableAddressLength are invalid
    error TokenBridge__InvalidAddressesLengths();

    /// @notice it is thown when the address length is already enabled
    error TokenBridge__AddressLengthAlreadyEnabled();

    /// @notice it is thown when the address length is not enabled
    error TokenBridge__AddressLengthNotEnabled();

    /// @notice it is thown when the chain is not yet supported
    error TokenBridge__NotYetSupportedChain();

    /// @notice it is thown when the amount is zero
    error TokenBridge__NoZeroAmount();

    /// @notice it is thown when the balance is insufficient
    error TokenBridge__InsufficientBalance();

    /// @notice it is thown when the gas is insufficient
    error TokenBridge__NotEnoughGas();

    /// @notice it is thown when the source address is not the one that matches the supported chain
    error TokenBridge__NotCorrectSourceAddress();

    /// @notice it is emitted when the chain is enabled
    event SupportedChainsEnabled(
        string indexed destinationChain,
        string indexed destinationAddress
    );

    /// @notice it is emitted when the chain is disabled
    event SupportedChainsDisabled(string indexed destinationChain);

    /// @notice it is emitted when the token has started its bridge from the source chain
    event TokenBridgeInitialised(
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

    /// @notice it is emitted when the address length is enabled
    /// @param length the address length
    event AddressLengthEnabled(uint256 indexed length);

    /// @notice it is emitted when the address length is disabled
    /// @param length the address length
    event AddressLengthDisabled(uint256 indexed length);
}
