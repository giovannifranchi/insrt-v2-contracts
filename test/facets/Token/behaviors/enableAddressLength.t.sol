// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { TokenBridge } from "../../Token/TokenBridge.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

/// @title Token_enableAddressLength
/// @notice This contract tests the functionalities of the enableAddressLength function
contract Token_enableAddressLength is ArbForkTest, TokenBridge {
    event AddressLengthEnabled(uint256 indexed length);

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

    /// @notice This function is used to test the enableAddressLength function can only be called by the owner
    function test_enableAddressLength_revertsWhen_callerIsNotOwner() public {
        vm.prank(ALICE);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
    }

    /// @notice This function is used to test the enableAddressLength function reverts if the length is zero
    function test_enableAddressLength_revertsWhen_lengthIsZero() public {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressLength.selector
        );
        ITokenBridge(tokenAddress).enableAddressLength(0);
    }

    /// @notice This function is used to test the enableAddressLength function reverts if the length is greater than the maximum length
    function test_enableAddressLength_revertsWhen_lengthIsGreaterThanMax()
        public
    {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressLength.selector
        );
        ITokenBridge(tokenAddress).enableAddressLength(MAX_LENGTH + 1);
    }

    /// @notice This function is used to test the enableAddressLength function reverts if the length is already enabled
    function test_enableAddressLength_revertsWhen_lengthIsAlreadyEnabled()
        public
    {
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
        vm.expectRevert(
            ITokenBridgeInternal
                .TokenBridge__AddressLengthAlreadyEnabled
                .selector
        );
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
    }

    /// @notice This function is used to test the enableAddressLength function correctly sets the length
    function test_enableAddressLength_setLegthCorrectly() public {
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
        assert(token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
    }

    /// @notice This function is used to test the enableAddressLength function emits the AddressLengthEnabled event
    function test_enableAddressLength_emitsAddressLengthEnabledEvent() public {
        vm.expectEmit(true, false, false, false);
        emit AddressLengthEnabled(EVM_ADDRESS_LENGTH);
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
    }

    /// @notice This function is used to test the enableAddressLength function can enable more than one length
    function test_enableAddressLength_moreThanOneLengthCanBeEnabledCorrectly()
        public
    {
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
        ITokenBridge(tokenAddress).enableAddressLength(20);
        assert(token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
        assert(token.exposed_isAddressLengthEnabled(20));
    }
}
