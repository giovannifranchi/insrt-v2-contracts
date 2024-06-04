// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintWithMint
/// @dev PerpetualMint test contract for testing expected attemptBatchMintWithMint behavior. Tested on an Arbitrum fork.
contract PerpetualMint_attemptBatchMintWithMint is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        perpetualMint.setConsolationFees(100 ether);

        token.addMintingContract(address(perpetualMint));

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);

        _activateVRFConsumer();
    }

    /// @dev Tests attemptBatchMintWithMint functionality when paying the full set collection mint price.
    function test_attemptBatchMintWithMintWithFullMintPrice() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        uint256 preMintTokenBalance = token.balanceOf(minter);

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedCollectionConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintWithMint functionality when paying a multiple of the set collection mint price.
    function test_attemptBatchMintWithMintWithMoreThanMintPrice() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        uint256 preMintTokenBalance = token.balanceOf(minter);

        // pay 10 times the collection mint price per spin
        MINT_PRICE = MINT_PRICE * 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedCollectionConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintWithMint functionality when paying a fraction of the set collection mint price.
    function test_attemptBatchMintWithMintWithPartialMintPrice() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        // pay 1/4th of the collection mint price per spin
        MINT_PRICE = MINT_PRICE / 4;

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedCollectionConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests attemptBatchMintWithMint functionality when a referrer address is passed.
    function test_attemptBatchMintWithMintWithReferrer() external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintMinterTokenBalance = token.balanceOf(minter);

        uint256 preMintReferrerTokenBalance = token.balanceOf(REFERRER);

        assert(preMintReferrerTokenBalance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        uint256 expectedMintReferralFee = (expectedMintFee *
            perpetualMint.collectionReferralFeeBP(COLLECTION)) /
            perpetualMint.BASIS();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired -
                        expectedCollectionConsolationFee -
                        expectedMintReferralFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                expectedMintFee - expectedMintReferralFee
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee
        );

        uint256 postMintMinterTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintMinterTokenBalance ==
                preMintMinterTokenBalance - expectedMintTokenBurned
        );

        uint256 postMintReferrerTokenBalance = token.balanceOf(REFERRER);

        assert(
            postMintReferrerTokenBalance ==
                expectedMintReferralFee * currentEthToMintRatio
        );
    }

    /// @dev Tests attemptBatchMintWithMint functionality when a collection mint fee distribution ratio is set.
    function test_attemptBatchMintWithMintWithCollectionMintFeeDistributionRatio()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP
        );

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedCollectionConsolationFee = (expectedEthRequired *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 expectedAdditionalDepositorFee = (expectedCollectionConsolationFee *
                TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP) /
                perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired -
                        expectedCollectionConsolationFee +
                        expectedAdditionalDepositorFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired -
                    expectedCollectionConsolationFee -
                    expectedMintFee +
                    expectedAdditionalDepositorFee
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            currentEthToMintRatio;

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when attempting to mint with an invalid fractional price per mint.
    function test_attemptBatchMintWithMintRevertsWhen_AttemptingToMintWithInvalidPricePerMint()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidPricePerMint.selector);

        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            2_500 ether + 1, // 2,500 $MINT + 1 wei (dust)
            TEST_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when attempting to mint with less than MINIMUM_PRICE_PER_SPIN.
    function test_attemptBatchMintWithMintRevertsWhen_AttemptingToMintForLessThanMinimumPricePerSpin()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.PricePerSpinTooLow.selector);

        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            1 ether - 1, // less than 1 $MINT
            TEST_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when attempting to mint for address(0) ($MINT).
    function test_attemptBatchMintWithMintRevertsWhen_AttemptingToMintForAddressZero()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        vm.expectRevert(
            IPerpetualMintInternal.InvalidCollectionAddress.selector
        );

        perpetualMint.attemptBatchMintWithMint(
            MINT_TOKEN_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            ZERO_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintWithMintRevertsWhen_AttemptingZeroMints()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            ZERO_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when the contract is paused.
    function test_attemptBatchMintWithMintRevertsWhen_PausedStateIsTrue()
        external
    {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );
    }

    function _activateVRFConsumer() private {
        // grab the Chainlink VRF Coordinator's s_consumers storage slot
        bytes32 s_consumersStorageSlot = keccak256(
            abi.encode(
                TEST_VRF_SUBSCRIPTION_ID, // the test VRF subscription ID
                keccak256(
                    abi.encode(
                        address(perpetualMint), // the consumer contract address
                        2 // the s_consumers storage slot
                    )
                )
            )
        );

        vm.store(
            this.perpetualMintHelper().VRF_COORDINATOR(),
            s_consumersStorageSlot,
            bytes32(uint256(TEST_VRF_CONSUMER_NONCE)) // set nonce to 1 to activate the consumer
        );
    }
}
