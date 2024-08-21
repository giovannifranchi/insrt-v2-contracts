// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenStorage as Storage } from "./Storage.sol";
import { TokenInternal } from "./TokenInternal.sol";

import { ITokenBridgeInternal } from "./ITokenBridgeInternal.sol";

import { AxelarExecutable } from "@axelar/executable/AxelarExecutable.sol";

import { IAxelarGasService } from "@axelar/interfaces/IAxelarGasService.sol";

import { IAxelarGateway } from "@axelar/interfaces/IAxelarGateway.sol";

/// @title TokenBridgeInternal
/// @notice it contains internal functions of the TokenBridgeInternal contract
abstract contract TokenBridgeInternal is
    TokenInternal,
    AxelarExecutable,
    ITokenBridgeInternal
{
    /// @notice Minimum gas required to execute a transaction through Axelar Gateway
    uint256 public constant MIN_GAS_PER_TX = 0.001 ether;

    /// @notice Axelar Gas Service contract in charge of handling gas disposal on other chains
    IAxelarGasService public immutable axelarGasService;
    constructor(address gateway, address gasService) AxelarExecutable(gateway) {
        if (gasService == address(0)) revert TokenBridge__InvalidAddress();
        axelarGasService = IAxelarGasService(gasService);
    }

    /// @notice it checks if the destination chain is a valid input
    /// @param destinationChain the destination chain
    /// @return isDestinationChainValid
    function _isDestinationChainValid(
        string calldata destinationChain
    ) internal pure returns (bool isDestinationChainValid) {
        return isDestinationChainValid = bytes(destinationChain).length != 0;
    }

    /// @notice it checks if the destination address is a valid input
    /// @param destinationAddress the destination address
    /// @return isDestinationAddressValid
    function _isDestinationAddressValid(
        string calldata destinationAddress
    ) internal pure returns (bool isDestinationAddressValid) {
        return isDestinationAddressValid = bytes(destinationAddress).length != 0;
    }

    /// @notice it checks if the destination chain is supported
    /// @param destinationChain the destination chain
    /// @return isDestinationChainSupported
    function _isDestinationChainSupported(
        string calldata destinationChain
    ) internal view returns (bool isDestinationChainSupported) {
        return
            isDestinationChainSupported = bytes(Storage.layout().supportedChains[destinationChain]).length !=
            0;
    }

    /// @notice it calculates the total balance of a user
    /// @param user the user address
    /// @dev it uses the balanceOf and claimableTokens functions of the token
    /// @return totalBalance
    function _calculateUserTotalBalance(
        address user
    ) internal view returns (uint256 totalBalance) {
        uint256 currentBalance = _balanceOf(user);
        uint256 currentAccruals = _claimableTokens(user);
        return totalBalance = currentBalance + currentAccruals;
    }

    /// @notice it claims and burns tokens
    /// @param user the user address
    /// @param amount the amount of tokens to burn
    function _claimAndBurnTokens(address user, uint256 amount) internal {
        _claim(user);
        _burn(user, amount);
    }

    /// @notice it calculates the amount to burn
    /// @param amount the amount to burn
    /// @param totalBalance the total balance of the user
    /// @dev if the amount is set to type(uint256).max, it returns the total balance
    /// @return amountToBurn
    function _calculateAmountToBurn(
        uint256 amount,
        uint256 totalBalance
    ) internal pure returns (uint256 amountToBurn) {
        return amountToBurn = amount == type(uint256).max ? totalBalance : amount;
    }

    /// @notice it enables a supported chain
    /// @param destinationChain the destination chain
    /// @param destinationAddress the destination address
    function _enableSupportedChains(
        string calldata destinationChain,
        string calldata destinationAddress
    ) internal {
        if (!_isDestinationChainValid(destinationChain))
            revert TokenBridge__InvalidChain();
        if (!_isDestinationAddressValid(destinationAddress))
            revert TokenBridge__InvalidAddress();
        Storage.layout().supportedChains[destinationChain] = destinationAddress;
        emit SupportedChainsEnabled(destinationChain, destinationAddress);
    }

    /// @notice it disables a supported chain
    /// @param destinationChain the destination chain
    function _disableSupportedChains(
        string calldata destinationChain
    ) internal {
        if (!_isDestinationChainSupported(destinationChain))
            revert TokenBridge__NotYetSupportedChain();
        delete Storage.layout().supportedChains[destinationChain];
        emit SupportedChainsDisabled(destinationChain);
    }

    /// @notice it returns the supported chains
    /// @param destinationChain the destination chain
    /// @return destinationAddress
    function _getDestinationAddress(
        string calldata destinationChain
    ) internal view returns (string memory destinationAddress) {
        return destinationAddress = Storage.layout().supportedChains[destinationChain];
    }

    /// @notice it bridges a token from the source chain to the destination chain
    /// @param destinationChain the destination chain
    /// @param amount the amount of token to bridge
    /// @dev it emits a TokenBridgeInitialised event
    function _bridgeToken(
        string calldata destinationChain,
        uint256 amount
    ) internal {
        if (amount == 0) revert TokenBridge__NoZeroAmount();
        if (msg.value < MIN_GAS_PER_TX) revert TokenBridge__NotEnoughGas();

        uint256 totalBalance = _calculateUserTotalBalance(msg.sender);
        if (
            (amount > totalBalance && amount != type(uint256).max) ||
            totalBalance == 0
        ) revert TokenBridge__InsufficientBalance();

        uint256 amountToBurn = _calculateAmountToBurn(amount, totalBalance);
        _claimAndBurnTokens(msg.sender, amountToBurn);

        string memory contractAddress = _getDestinationAddress(destinationChain);
        bytes memory payload = abi.encode(amountToBurn, msg.sender);

        // Ensure to pay for the gas of the contract call on the destination chain
        axelarGasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            destinationChain,
            contractAddress,
            payload,
            msg.sender
        );

        // Call the contract on the destination chain
        gateway.callContract(destinationChain, contractAddress, payload);

        emit TokenBridgeInitialised(
            destinationChain,
            contractAddress,
            amountToBurn
        );
    }

    /// @notice it hashes a string
    /// @param str the string to hash
    /// @return hashedString
    /// @dev it is an utility function used to enable string comparison
    function _hashString(string memory str) internal pure returns (bytes32 hashedString) {
        return hashedString = keccak256(abi.encodePacked(str));
    }

    /// @inheritdoc AxelarExecutable
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        // store it in memory to call _hashString()
        string memory _sourceAddress = sourceAddress;

        if (
            _hashString(_getDestinationAddress(sourceChain)) !=
            _hashString(_sourceAddress)
        ) revert TokenBridge__NotCorrectSourceAddress();

        (uint256 amount, address receiver) = abi.decode(
            payload,
            (uint256, address)
        );

        _claim(receiver);
        _mint(amount, receiver);
        emit TokenBridgeFinalized(sourceChain, sourceAddress, amount, receiver);
    }
}
