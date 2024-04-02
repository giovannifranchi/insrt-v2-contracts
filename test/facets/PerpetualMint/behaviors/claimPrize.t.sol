// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { IERC1155MetadataExtensionInternal } from "../../../../contracts/facets/PerpetualMint/IERC1155MetadataExtensionInternal.sol";

/// @title PerpetualMint_claimPrize
/// @dev PerpetualMint test contract for testing expected claimPrize behavior. Tested on an Arbitrum fork.
contract PerpetualMint_claimPrize is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev test collection prize address
    address internal testCollection = address(0xdeadbeef);

    /// @dev test collection prize address encoded as uint256
    uint256 internal testTokenId = uint256(bytes32(abi.encode(testCollection)));

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        // legacy collection receipt mint
        vm.prank(minter);
        perpetualMint.mintReceipts(testCollection, 1);

        // collection receipt mint with floor price
        vm.prank(minter);
        perpetualMint.mintReceipts(
            testCollection,
            1,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        );
    }

    /// @dev Tests claimPrize functionality.
    function test_claimPrize() external {
        uint256 preClaimClaimerReceiptBalance = perpetualMint.balanceOf(
            minter,
            testTokenId
        );

        uint256 preClaimProtocolReceiptBalance = perpetualMint.balanceOf(
            address(perpetualMint),
            testTokenId
        );

        vm.prank(minter);
        perpetualMint.claimPrize(
            minter,
            testTokenId,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        );

        uint256 postClaimClaimerReceiptBalance = perpetualMint.balanceOf(
            minter,
            testTokenId
        );

        assert(
            postClaimClaimerReceiptBalance == preClaimClaimerReceiptBalance - 1
        );

        uint256 postClaimProtocolReceiptBalance = perpetualMint.balanceOf(
            address(perpetualMint),
            testTokenId
        );

        assert(
            postClaimProtocolReceiptBalance ==
                preClaimProtocolReceiptBalance + 1
        );
    }

    /// @dev Tests claimPrize emits PrizeClaimed event.
    function test_claimPrizeEmitsPrizeClaimed() external {
        vm.expectEmit();

        emit IPerpetualMintInternal.PrizeClaimed(
            minter,
            minter,
            testCollection,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        );

        vm.prank(minter);
        perpetualMint.claimPrize(
            minter,
            testTokenId,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        );
    }

    /// @dev Tests claimPrize reverts when claimer balance is insufficient.
    function test_claimPrizeRevertsWhen_ClaimerBalanceInsufficient() external {
        vm.expectRevert(
            IERC1155MetadataExtensionInternal
                .NotEnoughTokenValuesFoundToUnset
                .selector
        );

        vm.prank(minter);
        perpetualMint.claimPrize(
            minter,
            ++testTokenId,
            TEST_MINT_FOR_COLLECTION_FLOOR_PRICE
        ); // increment testTokenId to ensure balance is insufficient
    }
}
