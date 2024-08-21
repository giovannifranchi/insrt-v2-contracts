// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../TokenBridge.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";

/// @title TestBridgeToken
/// @notice This contract tests the functionalities of the bridgeToken function
/// @dev It inherits from the TokenWithBridge contract and the ArbForkTest contract
/// @dev For changing fork it is sufficient to change the ForkTest inheritance
contract TestBridgeToken is ArbForkTest, TokenBridge {
    error TokenBridge__UnsupportedChain();
    error TokenBridge__NoZeroAmount();
    error TokenBridge__InsufficientBalance();
    error TokenBridge__NotEnoughGas();

    /// @notice Event emitted by Axelar Gateway when a contract call is made properly
    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event TokenBridgeInitialised(
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

    /// @notice This function is used to test the onlySupportedChains modifier
    /// @dev It tests if bridging on an unsupported chain should not be supported
    function test_bridgingOnUnsupportedChainShouldNotBeSupported() public {
        vm.expectRevert(TokenBridge__UnsupportedChain.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging with zero amount should not be supported
    function test_bridgingWithZeroAmountShouldNotBeSupported() public {
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
    function test_bridgingMoreThanBalanceShouldNotBeSupported() public {
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
    function test_bridgingWithUintMaxShouldTransferAllBalance() public {
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
    function test_bridgingShouldTransferTheCorrectAmount() public {
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
    function test_bridgingShouldEmitAnAxelarEvent() public {
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
    function test_bridgingShouldEmitAnInternalEvent() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, false, tokenAddress);
        emit TokenBridgeInitialised(
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
    function test_bridgeCannotHappenIfMinNativeAmountIsNotPayed() public {
        _enableChain(OWNER);

        vm.expectRevert(TokenBridge__NotEnoughGas.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken(supportedChain, 10 ether);
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
