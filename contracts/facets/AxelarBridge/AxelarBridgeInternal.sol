// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { AxelarBridgeStorage as Storage } from "./Storage.sol";
import { IToken } from "../Token/IToken.sol";

/// @title AxelarBridgeInternal
/// @notice it contains internal functions of the AxelarBridge contract
contract AxelarBridgeInternal {
    /// @notice it check if the destination chain is a valid input
    /// @param _destinationChain the destination chain
    /// @return true if the destination chain is valid
    function _isDestinationChainValid(
        string calldata _destinationChain
    ) internal pure returns (bool) {
        return bytes(_destinationChain).length != 0;
    }

    /// @notice it check if the destination address is a valid input
    /// @param _destinationAddress the destination address
    /// @return true if the destination address is valid
    function _isDestinationAddressValid(
        string calldata _destinationAddress
    ) internal pure returns (bool) {
        return bytes(_destinationAddress).length != 0;
    }

    /// @notice it check if the destination chain is supported
    /// @param _destinationChain the destination chain
    /// @return true if the destination chain is supported
    function _isDestinationChainSuppoerted(
        string calldata _destinationChain
    ) internal view returns (bool) {
        return
            bytes(Storage.layout().supportedChains[_destinationChain]).length !=
            0;
    }

    /// @notice it calculates the total balance of a user
    /// @param _user the user address
    /// @dev it uses the balanceOf and claimableTokens functions of the token
    /// @return the total balance of the user which means its balance plus its accruals
    function _calculateUserTotalBalance(
        address _user
    ) internal view returns (uint256) {
        IToken token = IToken(address(this));
        uint256 currentBalance = token.balanceOf(_user);
        uint256 currentAccruals = token.claimableTokens(_user);
        return currentBalance + currentAccruals;
    }

    /// @notice it claims and burns tokens
    /// @param _user the user address
    /// @param _amount the amount of tokens to burn
    function _claimAndBurnTokens(address _user, uint256 _amount) internal {
        IToken token = IToken(address(this));
        token.claimFor(_user);
        token.burn(_user, _amount);
    }

    /// @notice it calculates the amount to burn
    /// @param _amount the amount to burn
    /// @param _totalBalance the total balance of the user
    /// @dev if the amount is set to type(uint256).max, it returns the total balance
    /// @return the amount to burn
    function _calculateAmountToBurn(
        uint256 _amount,
        uint256 _totalBalance
    ) internal pure returns (uint256) {
        return _amount == type(uint256).max ? _totalBalance : _amount;
    }
}
