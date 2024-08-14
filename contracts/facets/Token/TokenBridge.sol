// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IAxelarGateway } from "@axelar/interfaces/IAxelarGateway.sol";

import { AxelarExecutable } from "@axelar/executable/AxelarExecutable.sol";

import { IAxelarGasService } from "@axelar/interfaces/IAxelarGasService.sol";

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import { TokenStorage as Storage } from "./Storage.sol";

import { ITokenBridge } from "./ITokenBridge.sol";

import { TokenBridgeInternal } from "./TokenBridgeInternal.sol";

import { IToken } from "./IToken.sol";

/// @title TokenBridge
/// @notice it is the main contract for the Token Bridge
/// @dev it contains all the external functions of TokenBridge
contract TokenBridge is
    ITokenBridge,
    TokenBridgeInternal,
    AxelarExecutable,
    OwnableInternal
{
    /// @notice Minimum gas required to execute a transaction through Axelar Gateway
    uint256 public constant MIN_GAS_PER_TX = 0.001 ether;

    /// @notice Axelar Gas Service contract in charge of handling gas disposal on other chains
    IAxelarGasService public immutable axelarGasService;

    modifier onlySupportedChains(string calldata destinationChain) {
        if (!_isDestinationChainSuppoerted(destinationChain))
            revert TokenBridge__UnsupportedChain();
        _;
    }

    constructor(address gateway, address gasService) AxelarExecutable(gateway) {
        if (gasService == address(0)) revert TokenBridge__InvalidAddress();
        axelarGasService = IAxelarGasService(gasService);
    }

    /// @inheritdoc ITokenBridge
    function enableSupportedChains(
        string calldata destinationChain,
        string calldata destinationAddress
    ) external onlyOwner {
        if (!_isDestinationChainValid(destinationChain))
            revert TokenBridge__InvalidChain();
        if (!_isDestinationAddressValid(destinationAddress))
            revert TokenBridge__InvalidAddress();
        Storage.layout().supportedChains[destinationChain] = destinationAddress;
        emit SupportedChainsEnabled(destinationChain, destinationAddress);
    }

    /// @inheritdoc ITokenBridge
    function disableSupportedChains(
        string calldata destinationChain
    ) external onlyOwner {
        if (!_isDestinationChainSuppoerted(destinationChain))
            revert TokenBridge__NotYetSupportedChain();
        delete Storage.layout().supportedChains[destinationChain];
        emit SupportedChainsDisabled(destinationChain);
    }

    /// @inheritdoc ITokenBridge
    function supportedChains(
        string calldata destinationChain
    ) public view returns (string memory) {
        return Storage.layout().supportedChains[destinationChain];
    }

    /// @inheritdoc ITokenBridge
    function bridgeToken(
        string calldata destinationChain,
        uint256 amount
    ) external payable onlySupportedChains(destinationChain) {
        if (amount == 0) revert TokenBridge__NoZeroAmount();
        if (msg.value < MIN_GAS_PER_TX) revert TokenBridge__NotEnoughGas();

        uint256 totalBalance = _calculateUserTotalBalance(msg.sender);
        if (
            (amount > totalBalance && amount != type(uint256).max) ||
            totalBalance <= 0
        ) revert TokenBridge__InsufficientBalance();

        uint256 amountToBurn = _calculateAmountToBurn(amount, totalBalance);
        _claimAndBurnTokens(msg.sender, amountToBurn);

        string memory contractAddress = supportedChains(destinationChain);
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

        emit ToeknBridgeInitilised(
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
        IToken token = IToken(address(this));
        token.claimFor(receiver);
        token.mint(receiver, amount);
        emit TokenBridgeFinalized(sourceChain, sourceAddress, amount, receiver);
    }
}
