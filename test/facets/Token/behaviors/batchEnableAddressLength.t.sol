// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { TokenBridge } from "../TokenBridge.t.sol";
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

/// @title Token_batchEnableAddressLength
/// @notice it tests the batchEnableAddressLength function of the TokenBridge
contract Token_batchEnableAddressLength is ArbForkTest, TokenBridge {
    event AddressLengthsEnabled(uint256 indexed mask);

    address public ALICE = makeAddr("Alice");
    address public tokenAddress;
    uint256 public constant EVM_ADDRESS_LENGTH = 42;
    uint256 public constant SOLANA_ADDRESS_LENGTH = 32;
    uint256 public constant COSMOS_ADDRESS_LENGTH = 40;
    uint256 public constant POLKADOT_ADDRESS_LENGTH = 44;
    uint256[] public lengths = [
        EVM_ADDRESS_LENGTH,
        SOLANA_ADDRESS_LENGTH,
        COSMOS_ADDRESS_LENGTH,
        POLKADOT_ADDRESS_LENGTH
    ];

    function setUp() public override {
        super.setUp();
        initTokenBridge(ARBITRUM_AXELAR_GATEWAY, ARBITRUM_AXELAR_GAS_SERVICE);
        tokenAddress = address(token);
    }

    /// @notice it tests the batchEnableAddressLength function can only be called by the owner
    function test_batchEnableAddressLength_revertsWhen_callerIsNotOwner()
        public
    {
        vm.startPrank(ALICE);

        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        ITokenBridge(tokenAddress).batchEnableAddressLength(
            _createBitMask(lengths)
        );
    }

    /// @notice it tests the batchEnableAddressLength function reverts if the mask is zero
    function test_batchEnableAddressLength_revertsWhen_maskIsZero() public {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressesLengths.selector
        );
        ITokenBridge(tokenAddress).batchEnableAddressLength(0);
    }

    /// @notice it tests the batchEnableAddressLength function reverts if the mask has zero in it
    function test_batchEnableAddressLength_revertsWhen_maskHasZeroInIt()
        public
    {
        uint256[] memory newLengths = new uint256[](3);
        newLengths[0] = EVM_ADDRESS_LENGTH;
        newLengths[1] = 0;
        newLengths[2] = POLKADOT_ADDRESS_LENGTH;
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressesLengths.selector
        );
        ITokenBridge(tokenAddress).batchEnableAddressLength(
            _createBitMask(newLengths)
        );
    }

    /// @notice it tests the batchEnableAddressLength function correctly enables all lengths
    function test_batchEnableAddressLength_correctlyEnablesAlllengths() public {
        ITokenBridge(tokenAddress).batchEnableAddressLength(
            _createBitMask(lengths)
        );
        for (uint256 i = 0; i < lengths.length; i++) {
            assert(token.exposed_isAddressLengthEnabled(lengths[i]));
        }
    }

    /// @notice it tests the batchEnableAddressLength function emits an AddressLengthsEnabled event
    function test_batchEnableAddressLength_emitsAddressLengthsEnabledEvent()
        public
    {
        uint256 mask = _createBitMask(lengths);
        vm.expectEmit(true, false, false, false);
        emit AddressLengthsEnabled(mask);
        ITokenBridge(tokenAddress).batchEnableAddressLength(mask);
    }

    /// @notice it tests the batchEnableAddressLength function correctly sets the mask without overriding same existing active values
    function test_batchEnableAddressLength_correctlySetsMaskWithoutOverridingSameExistingActiveValues()
        public
    {
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
        assert(token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
        ITokenBridge(tokenAddress).batchEnableAddressLength(
            _createBitMask(lengths)
        );
        for (uint256 i = 0; i < lengths.length; i++) {
            assert(token.exposed_isAddressLengthEnabled(lengths[i]));
        }
    }

    /// @notice it tests the batchEnableAddressLength function correctly sets the mask without overriding different existing active values
    function test_batchEnableAddressLength_correctlySetsMaskWithoutOvverridingDifferentExistingActiveValues()
        public
    {
        ITokenBridge(tokenAddress).enableAddressLength(21);
        assert(token.exposed_isAddressLengthEnabled(21));
        ITokenBridge(tokenAddress).batchEnableAddressLength(
            _createBitMask(lengths)
        );
        for (uint256 i = 0; i < lengths.length; i++) {
            assert(token.exposed_isAddressLengthEnabled(lengths[i]));
        }
        assert(token.exposed_isAddressLengthEnabled(21));
    }

    /// @notice it is a utility function to create a bitmask of address lengths
    function _createBitMask(
        uint256[] memory newLengths
    ) internal pure returns (uint256 mask) {
        for (uint256 i = 0; i < newLengths.length; i++) {
            mask |= (1 << newLengths[i]);
        }
    }
}
