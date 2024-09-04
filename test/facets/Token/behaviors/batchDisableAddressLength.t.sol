// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { TokenBridge } from "../TokenBridge.t.sol";
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

/// @title Token_batchDisableAddressLength
/// @notice it tests the batchDisableAddressLength function of the TokenBridge
contract Token_batchDisableAddressLength is ArbForkTest, TokenBridge {
    event AddressLengthsDisabled(uint256 indexed mask);

    address public ALICE = makeAddr("Alice");
    address public OWNER = makeAddr("Owner");
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
        vm.startPrank(OWNER);
        super.setUp();
        initTokenBridge(ARBITRUM_AXELAR_GATEWAY, ARBITRUM_AXELAR_GAS_SERVICE);
        tokenAddress = address(token);
        vm.stopPrank();
    }

    /// @notice it tests the batchDisableAddressLength function can only be called by the owner
    function test_batchDisableAddressLength_revertsWhen_callerIsNotOwner()
        public
    {
        _enableAddressLengths(OWNER);

        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).batchDisableAddressLength(
            _createBitMask(lengths)
        );
        vm.stopPrank();
    }

    /// @notice it tests the batchDisableAddressLength function reverts if the mask is zero
    function test_batchDisableAddressLength_revertsWhen_maskIsZero() public {
        _enableAddressLengths(OWNER);

        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressesLengths.selector
        );
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).batchDisableAddressLength(0);
    }

    /// @notice it tests the batchDisableAddressLength function reverts if the mask has zero in it
    function test_batchDisableAddressLength_revertsWhen_maskHasZeroInIt()
        public
    {
        _enableAddressLengths(OWNER);

        uint256[] memory newLengths = new uint256[](3);
        newLengths[0] = EVM_ADDRESS_LENGTH;
        newLengths[1] = 0;
        newLengths[2] = POLKADOT_ADDRESS_LENGTH;

        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddressesLengths.selector
        );
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).batchDisableAddressLength(
            _createBitMask(newLengths)
        );
    }

    /// @notice it tests the batchDisableAddressLength function correctly disables all lengths
    function test_batchDisableAddressLength_correctlyDisablesAllLengths()
        public
    {
        _enableAddressLengths(OWNER);

        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).batchDisableAddressLength(
            _createBitMask(lengths)
        );

        for (uint256 i = 0; i < lengths.length; i++) {
            assert(!token.exposed_isAddressLengthEnabled(lengths[i]));
        }
    }

    /// @notice it tests the batchDisableAddressLength function emits an AddressLengthsDisabled event
    function test_batchDisableAddressLength_emitsAddressLengthsDisabledEvent()
        public
    {
        _enableAddressLengths(OWNER);

        uint256 mask = _createBitMask(lengths);
        vm.expectEmit(true, false, false, false);
        emit AddressLengthsDisabled(mask);
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).batchDisableAddressLength(mask);
    }

    /// @notice it tests the batchDisableAddressLength function correctly disables some lengths without affecting the others
    function test_batchDisableAddressLength_itCorrectlyDisablesSomeLegthsWithoutAffectingTheOthers()
        public
    {
        _enableAddressLengths(OWNER);

        uint256[] memory newLengths = new uint256[](2);
        newLengths[0] = EVM_ADDRESS_LENGTH;
        newLengths[1] = POLKADOT_ADDRESS_LENGTH;

        uint256 disableMask = _createBitMask(newLengths);

        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).batchDisableAddressLength(disableMask);
        assert(token.exposed_isAddressLengthEnabled(COSMOS_ADDRESS_LENGTH));
        assert(token.exposed_isAddressLengthEnabled(SOLANA_ADDRESS_LENGTH));
        vm.stopPrank();
    }

    /// @notice it tests the batchDisableAddressLength function correctly disables lengths without affecting already disabled ones
    function test_batchDisableAddressLength_correctlyDisablesLengthsWithoutAffectingAlreadyDisabledOnes()
        public
    {
        _enableAddressLengths(OWNER);

        uint256[] memory newLengths = new uint256[](2);
        newLengths[0] = EVM_ADDRESS_LENGTH;
        newLengths[1] = SOLANA_ADDRESS_LENGTH;

        uint256 disableMask = _createBitMask(newLengths);

        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).disableAddressLength(COSMOS_ADDRESS_LENGTH);
        ITokenBridge(tokenAddress).disableAddressLength(SOLANA_ADDRESS_LENGTH);
        ITokenBridge(tokenAddress).batchDisableAddressLength(disableMask);
        assert(!token.exposed_isAddressLengthEnabled(COSMOS_ADDRESS_LENGTH));
        // Solana has been disabled twice and should be disabled
        assert(!token.exposed_isAddressLengthEnabled(SOLANA_ADDRESS_LENGTH));
        assert(!token.exposed_isAddressLengthEnabled(EVM_ADDRESS_LENGTH));
        // Polkadot is the only one that should be enabled
        assert(token.exposed_isAddressLengthEnabled(POLKADOT_ADDRESS_LENGTH));
        vm.stopPrank();
    }

    /// @notice it is a utility function to enable address lengths
    function _enableAddressLengths(address actor) internal {
        vm.startPrank(actor);
        ITokenBridge(tokenAddress).batchEnableAddressLength(
            _createBitMask(lengths)
        );
        vm.stopPrank();
    }

    /// @notice it is a utility function to create a bitmask of address lengths
    function _createBitMask(
        uint256[] memory lengths
    ) internal pure returns (uint256 mask) {
        for (uint256 i = 0; i < lengths.length; i++) {
            mask |= (1 << lengths[i]);
        }
    }
}
