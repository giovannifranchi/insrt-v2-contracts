// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintWithEthBase
/// @dev PerpetualMint_Base test contract for testing expected attemptBatchMintWithEth behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintWithEthBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_Base
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev Tests attemptBatchMintWithEth functionality when paying the full set collection mint price.
    function test_attemptBatchMintWithEthWithFullMintPrice() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.collectionConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees
        );

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees
        );
    }

    /// @dev Tests attemptBatchMintWithEth functionality when paying a multiple of the set collection mint price.
    function test_attemptBatchMintWithEthWithMoreThanMintPrice() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        // pay 10 times the collection mint price per spin
        MINT_PRICE = MINT_PRICE * 10;

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.collectionConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees
        );

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees
        );
    }

    /// @dev Tests attemptBatchMintWithEth functionality when paying a fraction of the set collection mint price.
    function test_attemptBatchMintWithEthWithPartialMintPrice() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        // pay 1/4th of the collection mint price per spin
        MINT_PRICE = MINT_PRICE / 4;

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.collectionConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees
        );

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees
        );
    }

    /// @dev Tests attemptBatchMintWithEth functionality when a referrer address is passed.
    function test_attemptBatchMintWithEthWithReferrer() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        assert(REFERRER.balance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.collectionConsolationFeeBP()) /
                    perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintProtocolFee = ((MINT_PRICE * TEST_MINT_ATTEMPTS) *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        uint256 expectedMintReferralFee = (expectedMintProtocolFee *
            perpetualMint.collectionReferralFeeBP(COLLECTION)) /
            perpetualMint.BASIS();

        assert(
            postMintAccruedProtocolFees ==
                expectedMintProtocolFee - expectedMintReferralFee
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees -
                    expectedMintReferralFee
        );

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees
        );

        assert(REFERRER.balance == expectedMintReferralFee);
    }

    /// @dev Tests attemptBatchMintWithEth functionality when a collection mint fee distribution ratio is set.
    function test_attemptBatchMintWithEthWithCollectionMintFeeDistributionRatio()
        external
    {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        perpetualMint.setCollectionMintFeeDistributionRatioBP(
            COLLECTION,
            TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP
        );

        uint256 preCalculatedCollectionConsolationFee = ((MINT_PRICE *
            TEST_MINT_ATTEMPTS) * perpetualMint.collectionConsolationFeeBP()) /
            perpetualMint.BASIS();

        uint256 preCalculatedAdditionalDepositorFee = (preCalculatedCollectionConsolationFee *
                TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP) /
                perpetualMint.BASIS();

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preCalculatedCollectionConsolationFee -
                    preCalculatedAdditionalDepositorFee
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    preCalculatedCollectionConsolationFee -
                    postMintAccruedProtocolFees +
                    preCalculatedAdditionalDepositorFee
        );

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees
        );
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when attempting to mint with an incorrect msg value amount.
    function test_attemptBatchMintWithEthRevertsWhen_AttemptingToMintWithIncorrectMsgValue()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.IncorrectETHReceived.selector);

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS + 1
        }(COLLECTION, NO_REFERRER, TEST_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when attempting to mint with less than MINIMUM_PRICE_PER_SPIN.
    function test_attemptBatchMintWithEthRevertsWhen_AttemptingToMintWithLessThanMinimumPricePerSpin()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.PricePerSpinTooLow.selector);

        perpetualMint.attemptBatchMintWithEth(
            COLLECTION,
            NO_REFERRER,
            TEST_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when attempting zero mints.
    function test_attemptBatchMintWithEthRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert();

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, NO_REFERRER, ZERO_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when the contract is paused.
    function test_attemptBatchMintWithEthRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, NO_REFERRER, TEST_MINT_ATTEMPTS);
    }
}
