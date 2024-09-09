// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

/// @title ArbForkTest
/// @dev Base contract for Arbitrum forking test cases.
abstract contract ArbForkTest is Test {
    /// @dev Fetches and stores the Arbitrum RPC URL from a local .env file using the passed string as a key.
    string internal ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

    address public constant ARBITRUM_AXELAR_GATEWAY =
        0xe432150cce91c13a887f7D836923d5597adD8E31;

    address public constant ARBITRUM_AXELAR_GAS_SERVICE =
        0x2d5d7d31F671F86C782533cc367F14109a082712;

    /// @dev Identifier for the simulated Arbitrum fork.
    /// @notice Fork is created, available for selection, and selected by default.
    uint256 internal arbitrumFork = vm.createSelectFork(ARBITRUM_RPC_URL);
}
