// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../TokenBridge.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { IAxelarGasService } from "@axelar/interfaces/IAxelarGasService.sol";
import { IAxelarGateway } from "@axelar/interfaces/IAxelarGateway.sol";

/// @title Token_bridgeToken
/// @notice This contract tests the functionalities of the bridgeToken function
/// @dev It inherits from the TokenWithBridge contract and the ArbForkTest contract
/// @dev For changing fork it is sufficient to change the ForkTest inheritance
contract Token_bridgeToken is ArbForkTest, TokenBridge {
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
    /// @dev tthe amount to be bridged
    uint256 public constant BRIDGE_AMOUNT = 10 ether;
    /// @dev takes also into account the 0x prefix
    uint256 public constant EVM_ADDRESS_LENGHT = 42;

    function setUp() public virtual override {
        vm.startPrank(OWNER);
        super.setUp();
        initTokenBridge(ARBITRUM_AXELAR_GATEWAY, ARBITRUM_AXELAR_GAS_SERVICE);
        tokenAddress = address(token);
        token.addMintingContract(address(token));
        vm.stopPrank();

        assert(
            _assertContractIsPresent(token.mintingContracts(), tokenAddress)
        );

        vm.startPrank(MINTER);
        token.mint(ALICE, ALICE_BALANCE);
        vm.stopPrank();

        uint256 amountInFees = (ALICE_BALANCE * DISTRIBUTION_FRACTION_BP) /
            BASIS;
        assert(token.balanceOf(ALICE) == ALICE_BALANCE - amountInFees);

        uint256 aliceClaimable = token.claimableTokens(ALICE);

        vm.startPrank(ALICE);
        token.claim();
        actualAliceBalance = token.balanceOf(ALICE);

        assert(
            actualAliceBalance == ALICE_BALANCE + aliceClaimable - amountInFees
        );

        vm.deal(ALICE, 100 ether);

        assert(address(ALICE).balance == 100 ether);
    }

    /// @notice This function is used to test the onlySupportedChains modifier
    /// @dev It tests if bridging on an unsupported chain should not be supported
    function test_bridgeToken_shouldRevert_whenBridgingOnUnsupportedChain()
        public
    {
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__UnsupportedChain.selector
        );

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            BRIDGE_AMOUNT
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging with zero amount should not be supported
    function test_bridgeToken_shouldRevert_whenBridgingWithZeroAmount() public {
        _enableChain(OWNER);

        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__NoZeroAmount.selector
        );

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            0
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging more than the balance should not be supported
    function test_bridgeToken_shouldRevert_whenBridgingMoreThanBalance()
        public
    {
        _enableChain(OWNER);

        vm.startPrank(ALICE);

        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__InsufficientBalance.selector
        );

        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            actualAliceBalance + 1
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if bridging with uint max transfers all the balance
    function test_bridgeToken_bridgingWithUintMax_shouldTransferAllBalance()
        public
    {
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
    function test_bridgeToken_bridgingShouldTransferTheCorrectAmount() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            BRIDGE_AMOUNT
        );

        vm.assertEq(token.balanceOf(ALICE), actualAliceBalance - BRIDGE_AMOUNT);
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It tests if the AxelarGateway event is emitted properly
    /// @dev It is the most important part since that event allows the bridging service to start
    function test_bridgeToken_emitsContractCallEvent() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, true, ARBITRUM_AXELAR_GATEWAY);
        emit ContractCall(
            tokenAddress,
            supportedChain,
            destinationAddress,
            keccak256(abi.encode(BRIDGE_AMOUNT, ALICE)),
            abi.encode(BRIDGE_AMOUNT, ALICE)
        );
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            BRIDGE_AMOUNT
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It check if an internal event is emitted when initiating the bridge
    function test_bridgeToken_emitsTokenBridgeInitialisedEvent() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, false, tokenAddress);
        emit TokenBridgeInitialised(
            supportedChain,
            destinationAddress,
            BRIDGE_AMOUNT
        );
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            BRIDGE_AMOUNT
        );
    }

    /// @notice This function is used to test the bridgeToken function
    /// @dev It checks if the min amount of msg.value is sent with the transaction in order to fullfill AxelarGasService requirements
    /// @dev If the complete operation costs less than the value sent the value in excess gets refunded
    function test_bridgeToken_shouldRevert_ifMinNativeAmountIsNotPayed()
        public
    {
        _enableChain(OWNER);

        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__NotEnoughGas.selector
        );

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).bridgeToken(supportedChain, BRIDGE_AMOUNT);
    }

    /// @notice This function makes sure that the call to the AxelarGasService is made with the correct parameters
    function test_bridgeToken_callToAxelarGasServiceShouldHappen() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        bytes memory payload = abi.encode(BRIDGE_AMOUNT, ALICE);
        bytes memory data = abi.encodeWithSelector(
            IAxelarGasService.payNativeGasForContractCall.selector,
            tokenAddress,
            supportedChain,
            destinationAddress,
            payload,
            ALICE
        );
        vm.expectCall(ARBITRUM_AXELAR_GAS_SERVICE, data);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            BRIDGE_AMOUNT
        );
    }

    /// @notice This function makes sure that the call to the AxelarGateway is made with the correct parameters
    function test_bridgeToken_callToGatewayShouldHappen() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        bytes memory payload = abi.encode(BRIDGE_AMOUNT, ALICE);
        bytes memory data = abi.encodeWithSelector(
            IAxelarGateway.callContract.selector,
            supportedChain,
            destinationAddress,
            payload
        );
        vm.expectCall(ARBITRUM_AXELAR_GATEWAY, data);
        ITokenBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            BRIDGE_AMOUNT
        );
    }

    /// @notice It is a utility function to enable supported chains
    function _enableChain(address _user) internal {
        vm.startPrank(_user);

        ITokenBridge(tokenAddress).enableAddressLength(EVM_ADDRESS_LENGHT);

        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }

    /// @notice It is a utility function to check if a contract is present in the minting contracts
    function _assertContractIsPresent(
        address[] memory mintingContracts,
        address targetContract
    ) internal pure returns (bool isContractPresent) {
        for (uint256 i = 0; i < mintingContracts.length; i++) {
            if (mintingContracts[i] == targetContract) {
                isContractPresent = true;
                break;
            }
        }

        return isContractPresent;
    }
}
