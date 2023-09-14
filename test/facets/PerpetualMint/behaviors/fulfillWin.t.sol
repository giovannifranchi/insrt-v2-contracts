// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC173 } from "@solidstate/contracts/interfaces/IERC173.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { AssetType } from "../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMint_fulfillWin
/// @dev PerpetualMint test contract for testing expected behavior of the fulfillWin function
contract PerpetualMint_fulfillWin is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    using stdStorage for StdStorage;

    // set winner address
    address internal constant WINNER = address(123123123);

    // Arbitrum mainnet SMOL_CARS ERC721 collection
    address internal constant SMOL_CARS =
        address(0xB16966daD2B5a5282b99846B23dcDF8C47b6132C);

    // Arbitrum mainnet BRIDGEWORLD ERC1155 collcetion
    address internal constant BRIDGEWORLD =
        address(0xF3d00A2559d84De7aC093443bcaAdA5f4eE4165C);

    // calculate receipt ID for Open Pen collection
    uint256 internal constant SMOL_CARS_RECEIPT_ID =
        uint256(bytes32(abi.encode(SMOL_CARS)));

    // calculate receipt ID for Parallel Alpha collection
    uint256 internal constant BRIDGEWORLD_RECEIPT_ID =
        uint256(bytes32(abi.encode(BRIDGEWORLD)));

    // token ID of won asset for SMOL_CARS collection
    uint256 internal constant SMOL_CARS_TOKEN_ID = 181;

    // token ID of won asset for BRIDGEWORLD collection
    uint256 internal constant BRIDGEWORLD_TOKEN_ID = 8;

    // protocol owner
    address internal OWNER;

    function setUp() public virtual override {
        super.setUp();

        // grab owner
        OWNER = IERC173(address(perpetualMint)).owner();

        // transfer ERC721 asset to owner
        address ownerToImpersonate = IERC721(SMOL_CARS).ownerOf(
            SMOL_CARS_TOKEN_ID
        );

        vm.prank(ownerToImpersonate);
        IERC721(SMOL_CARS).transferFrom(
            ownerToImpersonate,
            OWNER,
            SMOL_CARS_TOKEN_ID
        );

        assert(IERC721(SMOL_CARS).ownerOf(SMOL_CARS_TOKEN_ID) == OWNER);

        // approve PerpetualMint for ERC721 asset
        vm.prank(OWNER);
        IERC721(SMOL_CARS).setApprovalForAll(address(perpetualMint), true);

        // store balance for owner of ERC1155 asset
        stdstore
            .target(BRIDGEWORLD)
            .sig(IERC1155.balanceOf.selector)
            .with_key(OWNER)
            .with_key(BRIDGEWORLD_TOKEN_ID)
            .checked_write(1);

        assert(
            IERC1155(BRIDGEWORLD).balanceOf(OWNER, BRIDGEWORLD_TOKEN_ID) == 1
        );

        // approve PerpetualMint for ERC1155 asset
        vm.prank(OWNER);
        IERC1155(BRIDGEWORLD).setApprovalForAll(address(perpetualMint), true);
    }

    /// @dev ensures fulfillWin transfers the ERC721 asset to the winner
    function test_fulfillWinTransferERC721AssetFromOwnerToWinnerWhenAssetTypeIsERC721()
        public
    {
        perpetualMint.exposed_mint(WINNER, SMOL_CARS_RECEIPT_ID);

        assert(IERC721(SMOL_CARS).ownerOf(SMOL_CARS_TOKEN_ID) != WINNER);

        vm.prank(OWNER);
        perpetualMint.fulfillWin(
            WINNER,
            SMOL_CARS,
            SMOL_CARS_TOKEN_ID,
            AssetType.ERC721
        );

        assert(IERC721(SMOL_CARS).ownerOf(SMOL_CARS_TOKEN_ID) == WINNER);
    }

    /// @dev ensures fulfillWin transfers the ERC1155 asset to the winner
    function test_fulfillWinTransferERC1155AssetFromOwnerToWinnerWhenAssetTypeIsECR1155()
        public
    {
        perpetualMint.exposed_mint(WINNER, BRIDGEWORLD_RECEIPT_ID);

        uint256 oldBalance = IERC1155(BRIDGEWORLD).balanceOf(
            WINNER,
            BRIDGEWORLD_TOKEN_ID
        );

        vm.prank(OWNER);
        perpetualMint.fulfillWin(
            WINNER,
            BRIDGEWORLD,
            BRIDGEWORLD_TOKEN_ID,
            AssetType.ERC1155
        );

        uint256 newBalance = IERC1155(BRIDGEWORLD).balanceOf(
            WINNER,
            BRIDGEWORLD_TOKEN_ID
        );

        assert(newBalance - oldBalance == 1);
    }

    /// @dev ensures fulfillWin burns the collection receipt of the user
    function test_fulfillWinBurnsWinnerCollectionReceipt() public {
        perpetualMint.exposed_mint(WINNER, SMOL_CARS_RECEIPT_ID);

        assert(
            perpetualMint.exposed_balanceOf(WINNER, SMOL_CARS_RECEIPT_ID) == 1
        );

        vm.prank(OWNER);
        perpetualMint.fulfillWin(
            WINNER,
            SMOL_CARS,
            SMOL_CARS_TOKEN_ID,
            AssetType.ERC721
        );

        assert(
            perpetualMint.exposed_balanceOf(WINNER, SMOL_CARS_RECEIPT_ID) == 0
        );
    }

    /// @dev ensures fulfillWin emits the WinFulfilled event
    function test_fulfillWinEmitsWinFulfilledEvent() public {
        perpetualMint.exposed_mint(WINNER, SMOL_CARS_RECEIPT_ID);
        vm.expectEmit();
        emit IPerpetualMintInternal.WinFulfilled(
            WINNER,
            SMOL_CARS,
            SMOL_CARS_TOKEN_ID
        );

        vm.prank(OWNER);
        perpetualMint.fulfillWin(
            WINNER,
            SMOL_CARS,
            SMOL_CARS_TOKEN_ID,
            AssetType.ERC721
        );
    }

    /// @dev tests that fulfillWin will revert if called by non-owner
    function test_fulfillWinRevertsWhen_CalledByNonOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(NON_OWNER);
        perpetualMint.fulfillWin(NON_OWNER, SMOL_CARS, 1, AssetType.ERC721);
    }
}
