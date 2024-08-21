// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { TokenBridge } from "../TokenBridge.t.sol";
import { ITokenBridge } from "../../../../contracts/facets/Token/ITokenBridge.sol";
import { MockGateway } from "@axelar/test/mocks/MockGateway.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenBridgeInternal } from "../../../../contracts/facets/Token/ITokenBridgeInternal.sol";
import { IAxelarExecutable } from "@axelar/interfaces/IAxelarExecutable.sol";

/// @title Execute
/// @notice This contract tests the functionalities of the execute function
contract Execute is TokenBridge, ArbForkTest {
    /// @dev an example of a supported chain
    string public supportedChain = "ethereum";
    /// @dev an example of a destination address, it is a random address
    string public destinationAddress =
        "0x6513Aedb4D1593BA12e50644401D976aebDc90d8";
    address public ALICE = makeAddr("Alice");
    address public OWNER = makeAddr("Owner");
    address public AXELAR_RELAYER = makeAddr("AxelarRelayer");
    address public tokenAddress;
    MockGateway public axelarGateway;
    address public axelarGasService = makeAddr("AxelarGasService");
    bytes32 internal constant SELECTOR_APPROVE_CONTRACT_CALL =
        keccak256("approveContractCall");
    uint256 public constant AMOUNT_TO_MINT = 10 ether;
    /// @dev it is a random address used to check if the system is resilient to exploits made with unsupported addresses
    string public exploiterAddress =
        "0x8643Aedb4D1593BA12e50644401D976aebDc90e8";

    function setUp() public virtual override {
        vm.startPrank(OWNER);
        super.setUp();
        axelarGateway = new MockGateway();
        initTokenBridge(address(axelarGateway), axelarGasService);
        tokenAddress = address(token);
        vm.stopPrank();
    }

    /// @notice This function is used to test the execute function
    /// @dev Its major aim is to prevent arbitrary calls to the contract to be possible
    /// @dev It checks wether the transaction has been approved by the AxelarGateway
    /// @dev Any address can call the execute function but the call will only be executed if the gateway has approved it
    /// @dev There is not a single defined address for Axelar relayers
    function test_executeCannotBeCalledIfGatewayHasNotApprovedTheCall() public {
        _enableChain(OWNER);

        bytes memory payload = abi.encode(AMOUNT_TO_MINT, ALICE);

        vm.expectRevert(IAxelarExecutable.NotApprovedByGateway.selector);

        vm.startPrank(ALICE);
        ITokenBridge(tokenAddress).execute(
            SELECTOR_APPROVE_CONTRACT_CALL,
            supportedChain,
            destinationAddress,
            payload
        );
    }

    function test_receiveContractCallAndExecute() public {
        _enableChain(OWNER);
        _approveContractCall();

        vm.startPrank(AXELAR_RELAYER);
        bytes memory payload = abi.encode(AMOUNT_TO_MINT, ALICE);
        ITokenBridge(tokenAddress).execute(
            SELECTOR_APPROVE_CONTRACT_CALL,
            supportedChain,
            destinationAddress,
            payload
        );
        vm.stopPrank();

        uint256 amountForFees = (AMOUNT_TO_MINT *
            token.distributionFractionBP()) / token.BASIS();
        vm.assertEq(token.balanceOf(ALICE), AMOUNT_TO_MINT - amountForFees);
    }

    function test_callMadeFromUnsupportedAddressReverts() public {
        _enableChain(OWNER);
        _approveContractCallWithUnsupportedAddress();

        vm.startPrank(AXELAR_RELAYER);
        bytes memory payload = abi.encode(AMOUNT_TO_MINT, ALICE);
        vm.expectRevert(
            ITokenBridgeInternal.TokenBridge__NotCorrectSourceAddress.selector
        );

        ITokenBridge(tokenAddress).execute(
            SELECTOR_APPROVE_CONTRACT_CALL,
            supportedChain,
            exploiterAddress,
            payload
        );
        vm.stopPrank();
    }

    /// @notice It is a utility function to enable supported chains
    function _enableChain(address _user) internal {
        vm.startPrank(_user);
        ITokenBridge(tokenAddress).enableSupportedChains(
            supportedChain,
            destinationAddress
        );
    }

    /// @notice It is a utility function to approve contract calls an bypass the original signature functionality
    function _approveContractCall() internal {
        vm.startPrank(AXELAR_RELAYER);

        bytes memory payload = abi.encode(AMOUNT_TO_MINT, ALICE);
        bytes32 payloadHash = keccak256(payload);
        bytes memory params = abi.encode(
            supportedChain,
            destinationAddress,
            tokenAddress,
            payloadHash,
            keccak256("sourceTxHash"),
            1
        );
        axelarGateway.approveContractCall(
            params,
            SELECTOR_APPROVE_CONTRACT_CALL
        );
    }
    /// @notice It is a utility function to approve contract calls made from unsupported addresses
    function _approveContractCallWithUnsupportedAddress() internal {
        vm.startPrank(AXELAR_RELAYER);

        bytes memory payload = abi.encode(AMOUNT_TO_MINT, ALICE);
        bytes32 payloadHash = keccak256(payload);
        bytes memory params = abi.encode(
            supportedChain,
            exploiterAddress,
            tokenAddress,
            payloadHash,
            keccak256("sourceTxHash"),
            1
        );
        axelarGateway.approveContractCall(
            params,
            SELECTOR_APPROVE_CONTRACT_CALL
        );
    }
}
