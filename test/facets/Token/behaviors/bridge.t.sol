// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../TokenBridge.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";

/// @title TestBridge
/// @notice This contract tests the functionalities of the Axelar Bridge
/// @dev It inherits from the TokenWithBridge contract and the ArbForkTest contract
/// @dev For chaging fork it is sufficient to twick the ForkTest inheritance
contract TestBridge is ArbForkTest, TokenBridge {
    error Ownable__NotOwner();
    error TokenBridge__InvalidChain();
    error TokenBridge__InvalidAddress();
    error TokenBridge__NotYetSupportedChain();
    error TokenBridge__UnsupportedChain();
    error TokenBridge__NoZeroAmount();
    error TokenBridge__InsufficientBalance();
    error NotApprovedByGateway();
    error TokenBridge__NotEnoughGas();

    event SupportedChainsEnabled(
        string indexed destinationChain,
        string indexed destinationAddress
    );

    event SupportedChainsDisabled(string indexed destinationChain);

    /// @notice Event emitted by Axelar Gateway when a contract call is made properly
    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ToeknBridgeInitilised(
        string indexed destinationChain,
        string indexed destinationAddress,
        uint256 indexed amount
    );

    /// @dev AxelarGatway selector for approving contract calls in events
    bytes32 internal constant SELECTOR_APPROVE_CONTRACT_CALL =
        keccak256("approveContractCall");

    /// @dev an example of a supported chain
    string public supportedChain = "ethereum";
    /// @dev an example of a destination address, it is a random address
    string public destinationAddress =
        "0x6513Aedb4D1593BA12e50644401D976aebDc90d8";
    address public ALICE = makeAddr("Alice");
    address public OWNER = makeAddr("Owner");
    uint256 public ALICE_BALANCE = 100 ether;
    /// @dev it Alice balance after claiming
    uint256 public actualAliceBalance;
    /// @dev address of the token proxy contract
    address public tokenAddress;

    function setUp() public virtual override {
        vm.startPrank(OWNER);
        super.setUp();
        initTokenBridge(ARBITRUM_AXELAR_GATEWAY, ARBITRUM_AXELAR_GAS_SERVICE);
        tokenAddress = address(token);
        token.addMintingContract(address(token));
        vm.stopPrank();

        vm.startPrank(MINTER);
        token.mint(ALICE, ALICE_BALANCE);
        vm.stopPrank();

        vm.startPrank(ALICE);
        token.claim();
        actualAliceBalance = token.balanceOf(ALICE);

        vm.deal(ALICE, 100 ether);
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if the owner can enable a new chain
    function test_OwnerCanSetNewChains() public {
        _enableChain(OWNER);

        vm.assertEq(
            ITokenBridge(tokenAddress).supportedChains(supportedChain),
            destinationAddress
        );
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if an event is emitted when a new chain is enabled
    function test_EnablingChainShouldEmitEvent() public {
        vm.expectEmit(true, true, false, false);
        emit SupportedChainsEnabled(supportedChain, destinationAddress);

        _enableChain(OWNER);
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if the owner can disable a chain
    function test_OwnerCanDisableChain() public {
        _enableChain(OWNER);

        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);

        vm.assertEq(
            ITokenBridge(tokenAddress).supportedChains(supportedChain),
            ""
        );
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if an event is emitted when a chain is disabled
    function test_DisablingChainShouldEmitEvent() public {
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );

        vm.expectEmit(false, false, false, true);
        emit SupportedChainsDisabled(supportedChain);

        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if only the owner can enable a new chain
    function test_OnlyOwnerCanEnableChain() public {
        vm.expectRevert(Ownable__NotOwner.selector);
        _enableChain(ALICE);
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if only the owner can disable a chain
    function test_OnlyOwnerCanDisableChain() public {
        _enableChain(OWNER);

        vm.expectRevert(Ownable__NotOwner.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if calling the function with an empty chain should not be supported
    function test_EnablingEmptyChainShouldNotBeSupported() public {
        vm.expectRevert(TokenBridge__InvalidChain.selector);

        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).enableSupportedChains(
            "",
            destinationAddress
        );
    }

    /// @notice This function is used to test the disableSupportedChains function
    /// @dev It tests if disabling a not enabled chain is supported
    function test_DisablingNonExistentChainShouldNotBeSupported() public {
        vm.expectRevert(TokenBridge__NotYetSupportedChain.selector);
        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    /// @notice This function is used to test the enableSupportedChains function
    /// @dev It tests if calling the function with an empty address should not be supported
    function test_EnablingChainWithEmptyAddressShouldNotBeSupported() public {
        vm.expectRevert(TokenBridge__InvalidAddress.selector);

        vm.startPrank(OWNER);
        ITokenBridge(tokenAddress).enableSupportedChains(supportedChain, "");
    }

    /// @notice This function is used to test the supportedChains function
    /// @dev It tests if the correct destination address is retrieved
    function test_CorrectDestinationAddressIsRetrieved() public {
        _enableChain(OWNER);

        vm.assertEq(
            ITokenBridge(tokenAddress).supportedChains(supportedChain),
            destinationAddress
        );
    }

    /// @notice This function is used to test the onlySupportedChains modifier
    /// @dev It tests if bridging on an unsupported chain should not be supported
    function test_BridgingOnUnsupportedChainShouldNotBeSupported() public {
        vm.expectRevert(TokenBridge__UnsupportedChain.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging with zero amount should not be supported
    function test_BridgingWithZeroAmountShouldNotBeSupported() public {
        _enableChain(OWNER);

        vm.expectRevert(TokenBridge__NoZeroAmount.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            0
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging more than the balance should not be supported
    function test_BridgingMoreThanBalanceShouldNotBeSupported() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);

        vm.expectRevert(TokenBridge__InsufficientBalance.selector);

        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            actualAliceBalance + 10
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging with uint max transfers all the balance
    function test_BridgingWithUintMaxShouldTransferAllBalance() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            type(uint256).max
        );

        vm.assertEq(token.balanceOf(ALICE), 0);
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging with a valid amount should transfer the correct amount
    function test_BridgingShouldTransferTheCorrectAmount() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );

        vm.assertEq(token.balanceOf(ALICE), actualAliceBalance - 10 ether);
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if the AxelarGateway event is emitted properly
    /// @dev It is the most important part since that event allows the bridging service to start
    function test_BridgingShouldEmitAnAxelarEvent() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, true, ARBITRUM_AXELAR_GATEWAY);
        emit ContractCall(
            tokenAddress,
            supportedChain,
            destinationAddress,
            keccak256(abi.encode(10 ether, ALICE)),
            abi.encode(10 ether, ALICE)
        );
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It check if an internal event is emitted when initiating the bridge
    function test_BridgingShouldEmitAnInternalEvent() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, false, tokenAddress);
        emit ToeknBridgeInitilised(
            supportedChain,
            destinationAddress,
            10 ether
        );
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It checks if the min amount of msg.value is sent with the transaction in order to fullfill AxelarGasService requirements
    /// @dev If the complete operation costs less than the value sent the value in excess gets refunded
    function test_BridgeCannotHappenIfMinNativeAmountIsNotPayed() public {
        _enableChain(OWNER);

        vm.expectRevert(TokenBridge__NotEnoughGas.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken(supportedChain, 10 ether);
    }

    /// @notice This function is used to test the execute function
    /// @dev Its major aim is to prevent arbitrary calls to the contract to be possible
    /// @dev It checks wether the transaction has been approved by the AxelarGateway
    function test_ExecuteCannotBeCalledIfGatewayHasNotApprovedTheCall() public {
        _enableChain(OWNER);

        bytes memory payload = abi.encode(10 ether, ALICE);

        vm.expectRevert(NotApprovedByGateway.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).execute(
            SELECTOR_APPROVE_CONTRACT_CALL,
            supportedChain,
            destinationAddress,
            payload
        );
    }

    /// @notice It is a utility function to enable supported chains
    function _enableChain(address _user) internal {
        vm.startPrank(_user);
        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }
}
