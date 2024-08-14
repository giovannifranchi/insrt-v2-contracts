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

    /// @notice it check if the destination chain is a valid input
    /// @param destinationChain the destination chain
    /// @return true if the destination chain is valid
    function _isDestinationChainValid(
        string calldata destinationChain
    ) internal pure returns (bool) {
        return bytes(destinationChain).length != 0;
    }

    /// @notice it check if the destination address is a valid input
    /// @param destinationAddress the destination address
    /// @return true if the destination address is valid
    function _isDestinationAddressValid(
        string calldata destinationAddress
    ) internal pure returns (bool) {
        return bytes(destinationAddress).length != 0;
    }

    /// @notice it check if the destination chain is supported
    /// @param destinationChain the destination chain
    /// @return true if the destination chain is supported
    function _isDestinationChainSuppoerted(
        string calldata destinationChain
    ) internal view returns (bool) {
        return
            bytes(Storage.layout().supportedChains[destinationChain]).length !=
            0;
    }

    /// @notice it calculates the total balance of a user
    /// @param user the user address
    /// @dev it uses the balanceOf and claimableTokens functions of the token
    /// @return the total balance of the user which means its balance plus its accruals
    function _calculateUserTotalBalance(
        address user
    ) internal view returns (uint256) {
        uint256 currentBalance = _balanceOf(user);
        uint256 currentAccruals = _claimableTokens(user);
        return currentBalance + currentAccruals;
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
    /// @return the amount to burn
    function _calculateAmountToBurn(
        uint256 amount,
        uint256 totalBalance
    ) internal pure returns (uint256) {
        return amount == type(uint256).max ? totalBalance : amount;
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
        if (!_isDestinationChainSuppoerted(destinationChain))
            revert TokenBridge__NotYetSupportedChain();
        delete Storage.layout().supportedChains[destinationChain];
        emit SupportedChainsDisabled(destinationChain);
    }

    /// @notice it returns the supported chains
    /// @param destinationChain the destination chain
    function _supportedChains(
        string calldata destinationChain
    ) internal view returns (string memory) {
        return Storage.layout().supportedChains[destinationChain];
    }

    /// @notice it bridges a token from the source chain to the destination chain
    /// @param destinationChain the destination chain
    /// @param amount the amount of token to bridge
    /// @dev it emits a ToeknBridgeInitilised event
    /// @dev it is payable because it needs to receive native tokens for gas functionalities
    function _bridgeToken(
        string calldata destinationChain,
        uint256 amount
    ) internal {
        if (amount == 0) revert TokenBridge__NoZeroAmount();
        if (msg.value < MIN_GAS_PER_TX) revert TokenBridge__NotEnoughGas();

        uint256 totalBalance = _calculateUserTotalBalance(msg.sender);
        if (
            (amount > totalBalance && amount != type(uint256).max) ||
            totalBalance <= 0
        ) revert TokenBridge__InsufficientBalance();

        uint256 amountToBurn = _calculateAmountToBurn(amount, totalBalance);
        _claimAndBurnTokens(msg.sender, amountToBurn);

        string memory contractAddress = _supportedChains(destinationChain);
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

    /// @inheritdoc AxelarExecutable
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        (uint256 amount, address receiver) = abi.decode(
            payload,
            (uint256, address)
        );
        _claim(receiver);
        _mint(amount, receiver);
        emit TokenBridgeFinalized(sourceChain, sourceAddress, amount, receiver);
    }
}
