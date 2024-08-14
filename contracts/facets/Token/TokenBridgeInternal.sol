// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenStorage as Storage } from "./Storage.sol";
import { IToken } from "./IToken.sol";

/// @title TokenBridgeInternal
/// @notice it contains internal functions of the TokenBridgeInternal contract
abstract contract TokenBridgeInternal {
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
        IToken token = IToken(address(this));
        uint256 currentBalance = token.balanceOf(user);
        uint256 currentAccruals = token.claimableTokens(user);
        return currentBalance + currentAccruals;
    }

    /// @notice it claims and burns tokens
    /// @param user the user address
    /// @param amount the amount of tokens to burn
    function _claimAndBurnTokens(address user, uint256 amount) internal {
        IToken token = IToken(address(this));
        token.claimFor(user);
        token.burn(user, amount);
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
}
