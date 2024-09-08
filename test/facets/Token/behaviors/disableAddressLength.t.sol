// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { TokenBridge } from "../../Token/TokenBridge.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

/// @title Token_disableAddressLength
/// @notice This contract tests the functionalities of the disableAddressLength function
contract Token_disableAddressLength is TokenBridge, ArbForkTest {
    event AddressLengthDisabled(uint256 indexed length);

    address public tokenAddress;
    address public ALICE = makeAddr("Alice");
    uint256 public constant MAX_LENGTH = type(uint8).max;
    /// @dev It is the length of the EVM address in bytes considering the 0x prefix
    uint8 public constant EVM_ADDRESS_LENGTH = 42;

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();
        initTokenBridge(ARBITRUM_AXELAR_GATEWAY, ARBITRUM_AXELAR_GAS_SERVICE);
        tokenAddress = address(token);

        // assert setup is correct
        assert(
            address(IAxelarExecutable(tokenAddress).gateway()) ==
                ARBITRUM_AXELAR_GATEWAY
        );
        assert(
            address(ITokenBridge(tokenAddress).getGasService()) ==
                ARBITRUM_AXELAR_GAS_SERVICE
        );
    }

    /// @notice This function is used to test the disableAddressLength function can only be called by the owner
    function test_disableAddressLength_revertsWhen_callerIsNotOwner() public {
        _enableAddressLength(EVM_ADDRESS_LENGTH);
        vm.prank(ALICE);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        ITokenBridge(tokenAddress).disableAddressLength(EVM_ADDRESS_LENGTH);
    }

    /// @notice This function is used to test the disableAddressLength function reverts if the length is zero
    function test_disableAddressLength_revertsWhen_lengthIsZero() public {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressLength.selector
        );
        ITokenBridge(tokenAddress).disableAddressLength(0);
    }

    /// @notice This function is used to test the disableAddressLength function reverts if the length is greater than the maximum length
    function test_disableAddressLength_revertsWhen_lengthIsGreaterThanMax()
        public
    {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressLength.selector
        );
        ITokenBridge(tokenAddress).disableAddressLength(MAX_LENGTH + 1);
    }

    /// @notice This function is used to test the disableAddressLength function reverts if the length is not enabled
    function test_disableAddressLength_revertsWhen_lengthIsNotEnabled() public {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__AddressLengthNotEnabled.selector
        );
        ITokenBridge(tokenAddress).disableAddressLength(EVM_ADDRESS_LENGTH);
    }

    /// @notice This function is used to test the disableAddressLength function correctly disables the address length
    function test_disableAddressLength_correctlyDisablesAddressLength() public {
        _enableAddressLength(EVM_ADDRESS_LENGTH);
        assert(token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
        ITokenBridge(tokenAddress).disableAddressLength(EVM_ADDRESS_LENGTH);
        assert(!token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
    }

    /// @notice This function is used to test the disableAddressLength function emits the AddressLengthDisabled event
    function test_disableAddressLength_emitsAddressLengthDisabledEvent()
        public
    {
        _enableAddressLength(EVM_ADDRESS_LENGTH);
        assert(token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
        vm.expectEmit(true, false, false, false);
        emit AddressLengthDisabled(EVM_ADDRESS_LENGTH);
        ITokenBridge(tokenAddress).disableAddressLength(EVM_ADDRESS_LENGTH);
    }

    /// @notice This function is used to test the disableAddressLength when multiple lengths are active
    function test_disableAddressLength_correctlyDisablesAddressLengthWhenMultipleLengthsAreActive()
        public
    {
        _enableAddressLength(EVM_ADDRESS_LENGTH);
        _enableAddressLength(20);
        assert(token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
        assert(token.exposed_isAddressLengthEnabled(20));
        ITokenBridge(tokenAddress).disableAddressLength(EVM_ADDRESS_LENGTH);
        assert(!token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
        assert(token.exposed_isAddressLengthEnabled(20));
    }

    /// @notice This is a helper function to enable the address length
    function _enableAddressLength(uint8 length) internal {
        ITokenBridge(tokenAddress).enableAddressLength(length);
    }
}
