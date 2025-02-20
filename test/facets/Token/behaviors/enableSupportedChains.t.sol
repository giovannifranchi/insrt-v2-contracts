// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../TokenBridge.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

/// @title Token_enableSupportedChains
/// @notice This contract tests the functionalities of the enableSupportedChains function
contract Token_enableSupportedChains is ArbForkTest, TokenBridge {
    event SupportedChainsEnabled(
        string indexed destinationChain,
        string indexed destinationAddress
    );

    /// @dev an example of a supported chain
    string public supportedChain = "ethereum";
    /// @dev an example of a destination address, it is a random address
    string public destinationAddress =
        "0x6513Aedb4D1593BA12e50644401D976aebDc90d8";
    address public OWNER = makeAddr("Owner");
    address public ALICE = makeAddr("Alice");

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

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if the owner can enable a new chain
    function test_enableSupportedChains_ownerCanEnableNewChains() public {
        _enableChain(OWNER);

        vm.assertEq(
            ITokenBridge(tokenAddress).getDestinationAddress(supportedChain),
            destinationAddress
        );
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if an event is emitted when a new chain is enabled
    function test_enableSupportedChains_emitsSupportedChainsEnabledEvent()
        public
    {
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);

        vm.expectEmit(true, true, false, false);
        emit SupportedChainsEnabled(supportedChain, destinationAddress);

        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if only the owner can enable a new chain
    function test_enableSupportedChains_revertsWhen_notOwnerAttemptsToEnableChains()
        public
    {
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGTH);
        vm.stopPrank();
        vm.startPrank(ALICE);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if calling the function with an empty chain should not be supported
    function test_enableSupportedChains_revertsWhen_enablingEmptyChains()
        public
    {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidChain.selector
        );

        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).enableSupportedChains(
            "",
            destinationAddress
        );
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if calling the function with an empty address should not be supported
    function test_enableSupportedChains_revertsWhen_enablingChainWithEmptyAddress()
        public
    {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InvalidAddress.selector
        );

        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).enableSupportedChains(supportedChain, "");
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
