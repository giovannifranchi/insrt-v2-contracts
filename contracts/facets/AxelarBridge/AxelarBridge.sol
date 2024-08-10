// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IAxelarGateway } from "@axelar/interfaces/IAxelarGateway.sol";

import { AxelarExecutable } from "@axelar/executable/AxelarExecutable.sol";

import { IAxelarGasService } from "@axelar/interfaces/IAxelarGasService.sol";

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import { AxelarBridgeStorage as Storage } from "./Storage.sol";

import { IAxelarBridge } from "./IAxelarBridge.sol";

import { AxelarBridgeInternal } from "./AxelarBridgeInternal.sol";

import { IToken } from "../Token/IToken.sol";

/// @title AxelarBridge
/// @notice it is the main contract for the Axelar Bridge
/// @dev it contains all the external functions of the Axelar Bridge
contract AxelarBridge is
    IAxelarBridge,
    AxelarBridgeInternal,
    AxelarExecutable,
    OwnableInternal
{
    IAxelarGasService public immutable gasService;

    modifier onlySupportedChains(string calldata _destinationChain) {
        if (!_isDestinationChainSuppoerted(_destinationChain))
            revert AxelarBridge__UnsupportedChain();
        _;
    }

    constructor(
        address _gateway,
        address _gasService
    ) AxelarExecutable(_gateway) {
        if (_gasService == address(0)) revert AxelarBridge__InvalidAddress();
        gasService = IAxelarGasService(_gasService);
    }

    /// @inheritdoc IAxelarBridge
    function enableSupportedChains(
        string calldata _destinationChain,
        string calldata _destinationAddress
    ) external onlyOwner {
        if (!_isDestinationChainValid(_destinationChain))
            revert AxelarBridge__InvalidChain();
        if (!_isDestinationAddressValid(_destinationAddress))
            revert AxelarBridge__InvalidAddress();
        Storage.layout().supportedChains[
            _destinationChain
        ] = _destinationAddress;
        emit SupportedChainsEnabled(_destinationChain, _destinationAddress);
    }

    /// @inheritdoc IAxelarBridge
    function disableSupportedChains(
        string calldata _destinationChain
    ) external onlyOwner {
        if (!_isDestinationChainSuppoerted(_destinationChain))
            revert AxelarBridge__NotYetSupportedChain();
        delete Storage.layout().supportedChains[_destinationChain];
        emit SupportedChainsDisabled(_destinationChain);
    }

    /// @inheritdoc IAxelarBridge
    function supportedChains(
        string calldata _destinationChain
    ) public view returns (string memory) {
        return Storage.layout().supportedChains[_destinationChain];
    }

    /// @inheritdoc IAxelarBridge
    function bridgeToken(
        string calldata _destinationChain,
        uint256 _amount
    ) external payable onlySupportedChains(_destinationChain) {
        if (_amount == 0) revert AxelarBridge__NoZeroAmount();

        uint256 totalBalance = _calculateUserTotalBalance(msg.sender);
        if (
            (_amount > totalBalance && _amount != type(uint256).max) ||
            totalBalance <= 0
        ) revert AxelarBridge__InsufficientBalance();

        uint256 amountToBurn = _calculateAmountToBurn(_amount, totalBalance);
        _claimAndBurnTokens(msg.sender, amountToBurn);

        string memory contractAddress = supportedChains(_destinationChain);
        bytes memory payload = abi.encode(amountToBurn, msg.sender);

        // Ensure to pay for the gas of the contract call on the destination chain
        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            _destinationChain,
            contractAddress,
            payload,
            msg.sender
        );

        // Call the contract on the destination chain
        gateway.callContract(_destinationChain, contractAddress, payload);

        emit ToeknBridgeInitilised(
            _destinationChain,
            contractAddress,
            amountToBurn
        );
    }

    /// @inheritdoc AxelarExecutable
    function _execute(
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override {
        (uint256 amount, address receiver) = abi.decode(
            _payload,
            (uint256, address)
        );
        IToken token = IToken(address(this));
        token.claimFor(receiver);
        token.mint(receiver, amount);
        emit TokenBridgeFinalized(
            _sourceChain,
            _sourceAddress,
            amount,
            receiver
        );
    }
}
