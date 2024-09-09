// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ITokenHarness
/// @dev Interface for TokenHarness contract
interface ITokenHarness {
    /// @notice exposes _accrueTokens functions
    /// @param account address of account
    function exposed_accrueTokens(address account) external;

    /// @notice exposes _beforeTokenTransfer
    /// @param from sender of tokens
    /// @param to receiver of tokens
    /// @param amount quantity of tokens transferred
    function exposed_beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    /// @notice exposes _isAddressLengthEnabled
    /// @param length length of address
    /// @return isAddressLengthEnabled
    function exposed_isAddressLengthEnabled(
        uint256 length
    ) external view returns (bool isAddressLengthEnabled);

    /// @notice modifies distribution fee
    /// @param newValue new value for distribution fee
    /// @dev modifies the original function to set the distribution fee to zero
    function modified_setDistributionFee(uint32 newValue) external;
}
