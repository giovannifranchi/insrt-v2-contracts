// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../TokenBridge.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

/// @title Token_disableSupportedChains
/// @notice This contract tests the functionalities of DisableSupportedChains function
contract Token_disableSupportedChains is ArbForkTest, TokenBridge {
    /// @notice Event emitted when a chain is disabled
    event SupportedChainsDisabled(string indexed destinationChain);

    /// @dev an example of a supported chain
    string public supportedChain = "ethereum";
    /// @dev an example of a destination address, it is a random address
    string public destinationAddress =
        "0x6513Aedb4D1593BA12e50644401D976aebDc90d8";
    address public ALICE = makeAddr("Alice");
    address public OWNER = makeAddr("Owner");

    /// @dev address of the token proxy contract
    address public tokenAddress;

    /// @dev takes also into account the 0x prefix
    uint256 public constant EVM_ADDRESS_LENGTH = 42;

    function setUp() public virtual override {
        vm.startPrank(OWNER);
        super.setUp();
        initTokenBridge(ARBITRUM_AXELAR_GATEWAY, ARBITRUM_AXELAR_GAS_SERVICE);
        tokenAddress = address(token);
        vm.stopPrank();
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if the owner can disable a chain
    function test_disableSupportedChains_ownerCanDisableChain() public {
        _enableChain(OWNER);

        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);

        vm.assertEq(
            ITokenBridge(tokenAddress).getDestinationAddress(supportedChain),
            ""
        );
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if an event is emitted when a chain is disabled
    function test_disableSupportedChains_emitsSupportedChainsDisabledEvent()
        public
    {
        _enableChain(OWNER);

        vm.startPrank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit SupportedChainsDisabled(supportedChain);

        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if only the owner can disable a chain
    function test_disableSupportedChains_revertsWhen_notOwnerAttemptsToDisableSupportedChains()
        public
    {
        _enableChain(OWNER);

        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if disabling a not enabled chain is supported
    function test_disableSupportedChains_revertsWhen_disablingNotSupportedChains()
        public
    {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__NotYetSupportedChain.selector
        );
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    /// @notice It is a utility function to enable supported chains
    function _enableChain(address _user) internal {
        vm.startPrank(_user);

        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);

        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }
}
