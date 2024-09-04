// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../TokenBridge.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";

/// @title Token_getDestinationAddress
/// @notice This contract tests the functionalities of supportedChain function
contract Token_getDestinationAddress is ArbForkTest, TokenBridge {
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

    /// @notice This function is used to test the supportedChains function
    /// @dev It tests if the correct destination address is retrieved
    function testFuzz_getDestinationAddress_correctDestinationAddressIsRetrieved(
        string calldata supportedChain,
        string calldata destinationAddress
    ) public {
        vm.assume(bytes(supportedChain).length > 0);
        vm.assume(bytes(destinationAddress).length == EVM_ADDRESS_LENGHT);

        _enableChain(OWNER, supportedChain, destinationAddress);

        vm.assertEq(
            ITokenBridge(tokenAddress).getDestinationAddress(supportedChain),
            destinationAddress
        );
    }

    /// @notice It is a utility function to enable supported chains
    function _enableChain(
        address _user,
        string calldata supportedChain,
        string calldata destinationAddress
    ) internal {
        vm.startPrank(_user);
        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGHT);
        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }
}
