// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenWithBridge } from "../TokenWithBridge.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IAxelarBridge } from "../../../../contracts/facets/AxelarBridge/IAxelarBridge.sol";

contract TestBridge is ArbForkTest, TokenWithBridge {
    error Ownable__NotOwner();
    error AxelarBridge__InvalidChain();
    error AxelarBridge__InvalidAddress();
    error AxelarBridge__NotYetSupportedChain();
    error AxelarBridge__UnsupportedChain();
    error AxelarBridge__NoZeroAmount();
    error AxelarBridge__InsufficientBalance();
    error NotApprovedByGateway();

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

    bytes32 internal constant SELECTOR_APPROVE_CONTRACT_CALL =
        keccak256("approveContractCall");

    string public supportedChain = "ethereum";
    string public destinationAddress =
        "0x6513Aedb4D1593BA12e50644401D976aebDc90d8"; // it is a random one
    address public ALICE = makeAddr("Alice");
    address public OWNER = makeAddr("Owner");
    uint256 public ALICE_BALANCE = 100 ether;
    uint256 public actualAliceBalance;
    address public tokenAddress;

    function setUp() public virtual override {
        // Call the setUp function of TokenWithBridge with the required arguments
        vm.startPrank(OWNER);
        super.setUp();
        initTokenWithBridge(
            ARBITRUM_AXELAR_GATEWAY,
            ARBITRUM_AXELAR_GAS_SERVICE
        );

        tokenAddress = address(token);

        // Additional setup code
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

    function test_OwnerCanSetNewChains() public {
        _enableChain(OWNER);

        vm.assertEq(
            IAxelarBridge(tokenAddress).supportedChains(supportedChain),
            destinationAddress
        );
    }

    function test_EnablingChainShouldEmitEvent() public {
        vm.expectEmit(true, true, false, false);
        emit SupportedChainsEnabled(supportedChain, destinationAddress);

        _enableChain(OWNER);
    }

    function test_OwnerCanDisableChain() public {
        _enableChain(OWNER);

        IAxelarBridge(tokenAddress).disableSupportedChains(supportedChain);

        vm.assertEq(
            IAxelarBridge(tokenAddress).supportedChains(supportedChain),
            ""
        );
    }

    function test_DisablingChainShouldEmitEvent() public {
        vm.startPrank(OWNER);
        IAxelarBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );

        vm.expectEmit(false, false, false, true);
        emit SupportedChainsDisabled(supportedChain);

        IAxelarBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    function test_OnlyOwnerCanEnableChain() public {
        vm.expectRevert(Ownable__NotOwner.selector);
        _enableChain(ALICE);
    }

    function test_OnlyOwnerCanDisableChain() public {
        _enableChain(OWNER);

        vm.expectRevert(Ownable__NotOwner.selector);

        vm.startPrank(ALICE);
        IAxelarBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    function test_EnablingEmptyChainShouldNotBeSupported() public {
        vm.expectRevert(AxelarBridge__InvalidChain.selector);

        vm.startPrank(OWNER);
        IAxelarBridge(tokenAddress).enableSupportedChains(
            "",
            destinationAddress
        );
    }

    function test_DisablingNonExistentChainShouldNotBeSupported() public {
        vm.expectRevert(AxelarBridge__NotYetSupportedChain.selector);
        vm.startPrank(OWNER);
        IAxelarBridge(tokenAddress).disableSupportedChains(supportedChain);
    }

    function test_EnablingChainWithEmptyAddressShouldNotBeSupported() public {
        vm.expectRevert(AxelarBridge__InvalidAddress.selector);

        vm.startPrank(OWNER);
        IAxelarBridge(tokenAddress).enableSupportedChains(supportedChain, "");
    }

    function test_BridgingOnUnsupportedChainShouldNotBeSupported() public {
        vm.expectRevert(AxelarBridge__UnsupportedChain.selector);

        vm.startPrank(ALICE);
        IAxelarBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );
    }

    function test_BridgingWithZeroAmountShouldNotBeSupported() public {
        _enableChain(OWNER);

        vm.expectRevert(AxelarBridge__NoZeroAmount.selector);

        vm.startPrank(ALICE);
        IAxelarBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            0
        );
    }

    function test_BridgingMoreThanBalanceShouldNotBeSupported() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);

        vm.expectRevert(AxelarBridge__InsufficientBalance.selector);

        IAxelarBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            actualAliceBalance + 10
        );
    }

    function test_BridgingWithUintMaxShouldTransferAllBalance() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        IAxelarBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            type(uint256).max
        );

        vm.assertEq(token.balanceOf(ALICE), 0);
    }

    function test_BridgingShouldTransferTheCorrectAmount() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        IAxelarBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );

        vm.assertEq(token.balanceOf(ALICE), actualAliceBalance - 10 ether);
    }

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
        IAxelarBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );
    }

    function test_BridgingShouldEmitAnInternalEvent() public {
        _enableChain(OWNER);

        vm.startPrank(ALICE);
        vm.expectEmit(true, true, true, false, tokenAddress);
        emit ToeknBridgeInitilised(
            supportedChain,
            destinationAddress,
            10 ether
        );
        IAxelarBridge(tokenAddress).bridgeToken{ value: 0.01 ether }(
            supportedChain,
            10 ether
        );
    }

    function test_ExecuteCannotBeCalledIfGatewayHasNotApprovedTheCall() public {
        _enableChain(OWNER);

        bytes memory payload = abi.encode(10 ether, ALICE);

        vm.expectRevert(NotApprovedByGateway.selector);

        vm.startPrank(ALICE);
        IAxelarBridge(tokenAddress).execute(
            SELECTOR_APPROVE_CONTRACT_CALL,
            supportedChain,
            destinationAddress,
            payload
        );
    }

    //========================================================================= UTILITIES ===================================================================================================

    function _enableChain(address _user) internal {
        vm.startPrank(_user);
        IAxelarBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }
}
