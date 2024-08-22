// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenStorage as Storage } from "./Storage.sol";
import { TokenInternal } from "./TokenInternal.sol";

import { ITokenBridgeInternal } from "./ITokenBridgeInternal.sol";

import { IAxelarGasService } from "@axelar/interfaces/IAxelarGasService.sol";

import { IAxelarGateway } from "@axelar/interfaces/IAxelarGateway.sol";

/// @title TokenBridgeInternal
/// @notice it contains internal functions of the TokenBridgeInternal contract
abstract contract TokenBridgeInternal is TokenInternal, ITokenBridgeInternal {
    /// @notice Minimum gas required to execute a transaction through Axelar Gateway
    uint256 public constant MIN_GAS_PER_TX = 0.001 ether;

    /// @notice Maximum address length that can be stored in a uint256 bitmap
    uint8 public constant MAX_ADDRESS_LENGTH = 255;

    /// @notice Axelar Gas Service contract in charge of handling gas disposal on other chains
    IAxelarGasService public immutable axelarGasService;

    constructor(address gasService) {
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
    ) internal view returns (bool isDestinationAddressValid) {
        return
            isDestinationAddressValid = _isAddressLengthEnabled(
                bytes(destinationAddress).length
            );
    }

    /// @notice it checks if the destination chain is supported
    /// @param destinationChain the destination chain
    /// @dev here it is sufficient to check whether the destination address is not empty because it passed the legth check earlier
    /// @return isDestinationChainSupported
    function _isDestinationChainSupported(
        string calldata destinationChain
    ) internal view returns (bool isDestinationChainSupported) {
        return
            isDestinationChainSupported =
                bytes(Storage.layout().supportedChains[destinationChain])
                    .length !=
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
        return
            amountToBurn = amount == type(uint256).max ? totalBalance : amount;
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
        return
            destinationAddress = Storage.layout().supportedChains[
                destinationChain
            ];
    }

    /// @notice it bridges a token from the source chain to the destination chain
    /// @param destinationChain the destination chain
    /// @param amount the amount of token to bridge
    /// @dev it emits a TokenBridgeInitialised event
    function _bridgeToken(
        string calldata destinationChain,
        uint256 amount,
        IAxelarGateway gateway
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

        string memory contractAddress = _getDestinationAddress(
            destinationChain
        );
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
    function _hashString(
        string memory str
    ) internal pure returns (bytes32 hashedString) {
        return hashedString = keccak256(abi.encodePacked(str));
    }

    /// @notice it enables multiple address lengths
    /// @param mask the address lengths passed through a bitmask
    /// @dev it could be useful to enable multiple address lengths at once for cases where chains have different address lengths (solana: 32 to 44)
    /// @dev while not very user-friendly, it is a powerful tool to enable multiple address lengths at once
    function _batchEnableAddressLength(uint256 mask) internal {
        // checks that the cannot set 0 as a valid address length
        if (mask == 0 || (mask & 1) != 0)
            revert TokenBridge__InvalidAddressesLengths();

        Storage.layout().allowedAddressLengthBitMap |= mask;
        emit AddressLengthsEnabled(mask);
    }

    /// @notice it disables multiple address lengths
    /// @param mask the address lengths passed through a bitmask
    /// @dev it could be useful to disable multiple address lengths at once for cases where chains have different address lengths (solana: 32 to 44)
    /// @dev while not very user-friendly, it is a powerful tool to enable multiple address lengths at once
    function _batchDisableAddressLength(uint256 mask) internal {
        if (mask == 0 || (mask & 1) != 0)
            revert TokenBridge__InvalidAddressesLengths();

        Storage.layout().allowedAddressLengthBitMap &= ~mask;
        emit AddressLengthsDisabled(mask);
    }

    /// @notice it enables an address length
    /// @param length the address length
    function _enableAddressLength(uint256 length) internal {
        if (length == 0 || length > MAX_ADDRESS_LENGTH)
            revert TokenBridge__InvalidAddressLength();
        if (_isAddressLengthEnabled(length))
            revert TokenBridge__AddressLengthAlreadyEnabled();

        _toggleAddressLenght(length);
        emit AddressLengthEnabled(length);
    }

    /// @notice it disables an address length
    /// @param length the address length
    function _disableAddressLength(uint256 length) internal {
        if (length == 0 || length > MAX_ADDRESS_LENGTH)
            revert TokenBridge__InvalidAddressLength();
        if (!_isAddressLengthEnabled(length))
            revert TokenBridge__AddressLengthNotEnabled();

        _toggleAddressLenght(length);
        emit AddressLengthDisabled(length);
    }

    /// @notice it toggles the allowed address length
    /// @param length the address length
    function _toggleAddressLenght(uint256 length) internal {
        Storage.layout().allowedAddressLengthBitMap ^= (1 << length);
    }

    /// @notice it checks if the address length is enabled
    /// @param length the address length
    /// @return isAddressLengthEnabled
    function _isAddressLengthEnabled(
        uint256 length
    ) internal view returns (bool isAddressLengthEnabled) {
        return
            isAddressLengthEnabled =
                (_getAddressLengthBitMap() & (1 << length)) != 0;
    }

    /// @notice it returns the address length bitmap
    /// @return addressLengthBitMap
    function _getAddressLengthBitMap()
        internal
        view
        returns (uint256 addressLengthBitMap)
    {
        return
            addressLengthBitMap = Storage.layout().allowedAddressLengthBitMap;
    }

    /// @notice it executes a transaction call from the gateway
    /// @param payload the payload
    /// @param sourceChain the source chain
    /// @param sourceAddress the source address
    function _execute(
        bytes calldata payload,
        string calldata sourceChain,
        string calldata sourceAddress
    ) internal {
        // store it in memory to call _hashString()
        string memory _sourceAddress = sourceAddress;

        // This check is made in oder to ensure that no one else can make a valid call to this contract except registered addresses
        if (
            _hashString(_getDestinationAddress(sourceChain)) !=
            _hashString(_sourceAddress)
        ) revert TokenBridge__NotCorrectSourceAddress();

        (uint256 amount, address receiver) = abi.decode(
            payload,
            (uint256, address)
        );

        _claim(receiver);
        _mint(receiver, amount);
        emit TokenBridgeFinalized(sourceChain, sourceAddress, amount, receiver);
    }
}
