// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { MintTokenTiersData, RequestData, TiersData, VRFConfig } from "./Storage.sol";

/// @title IPerpetualMintInternal
/// @dev Interface containing all errors and events used in the PerpetualMint facet contract
interface IPerpetualMintInternal {
    /// @notice thrown when an incorrect amount of ETH is received
    error IncorrectETHReceived();

    /// @notice thrown when there are not enough consolation fees accrued to faciliate
    /// minting with $MINT
    error InsufficientConsolationFees();

    /// @notice thrown when the potential mint for ETH max payout is greater than mint earnings
    /// when adjusted using the mint earnings buffer
    error InsufficientMintEarnings();

    /// @notice thrown when an invalid collection address is provided when minting for a collection
    /// for now, this is only thrown when attempting to address(0) when minting for a collection
    error InvalidCollectionAddress();

    /// @notice thrown when attempting to mint an invalid number of tokens (0 or over a certain limit)
    error InvalidNumberOfMints();

    /// @notice thrown when the specified price per mint in $MINT is not a whole number
    error InvalidPricePerMint();

    /// @dev thrown when attempting to update a collection risk and
    /// there are pending mint requests in a collection
    error PendingRequests();

    /// @dev thrown when the mint price per spin is less than MINIMUM_PRICE_PER_SPIN
    error PricePerSpinTooLow();

    /// @dev thrown when attempting to redeem when redeeming is paused
    error RedeemPaused();

    /// @notice thrown when fulfilled random words do not match for attempted mints
    error UnmatchedRandomWords();

    /// @notice thrown when VRF subscription LINK balance falls below the required threshold
    error VRFSubscriptionBalanceBelowThreshold();

    /// @notice emitted when the risk for Blast yield is set
    /// @param risk risk of Blast yield
    event BlastYieldRiskSet(uint32 risk);

    /// @notice emitted when a claim is cancelled
    /// @param claimer address of rejected claimer
    /// @param collection address of rejected claim collection
    event ClaimCancelled(address claimer, address indexed collection);

    /// @notice emitted when the mint fee distribution ratio for a collection is updated
    /// @param collection address of collection
    /// @param ratioBP new mint fee distribution ratio in basis points
    event CollectionMintFeeRatioUpdated(address collection, uint32 ratioBP);

    /// @notice emitted when the mint multiplier for a collection is set
    /// @param collection address of collection
    /// @param multiplier multiplier of collection
    event CollectionMultiplierSet(address collection, uint256 multiplier);

    /// @notice emitted when the mint referral fee in basis points for a collection is set
    /// @param collection address of collection
    /// @param referralFeeBP mint referral fee of collection in basis points
    event CollectionReferralFeeBPSet(address collection, uint32 referralFeeBP);

    /// @notice emitted when the risk for a collection is set
    /// @param collection address of collection
    /// @param risk risk of collection
    event CollectionRiskSet(address collection, uint32 risk);

    /// @notice emitted when the collection consolation fee is set
    /// @param collectionConsolationFeeBP minting for collection consolation fee in basis points
    event CollectionConsolationFeeSet(uint32 collectionConsolationFeeBP);

    /// @notice emitted when the consolation fees are funded
    /// @param funder address of funder
    /// @param amount amount of ETH funded
    event ConsolationFeesFunded(address indexed funder, uint256 amount);

    /// @notice emitted when the default mint referral fee for collections is set
    /// @param referralFeeBP new default mint referral fee for collections in basis points
    event DefaultCollectionReferralFeeBPSet(uint32 referralFeeBP);

    /// @notice emitted when the ETH:MINT ratio is set
    /// @param ratio value of ETH:MINT ratio
    event EthToMintRatioSet(uint256 ratio);

    /// @notice emitted when the mint earnings buffer is set
    /// @param mintEarningsBufferBP mint earnings buffer in basis points
    event MintEarningsBufferSet(uint32 mintEarningsBufferBP);

    /// @notice emitted when the mint fee is set
    /// @param mintFeeBP mint fee in basis points
    event MintFeeSet(uint32 mintFeeBP);

    /// @notice emitted when the mint for ETH consolation fee is set
    /// @param mintForEthConsolationFeeBP minting for ETH consolation fee in basis points
    event MintForEthConsolationFeeSet(uint32 mintForEthConsolationFeeBP);

    /// @notice emitted when the mint price of a collection is set
    /// @param collection address of collection
    /// @param price mint price of collection
    event MintPriceSet(address collection, uint256 price);

    /// @notice emitted when the mint for $MINT consolation fee is set
    /// @param mintTokenConsolationFeeBP minting for $MINT consolation fee in basis points
    event MintTokenConsolationFeeSet(uint32 mintTokenConsolationFeeBP);

    /// @notice emitted when the address of the $MINT token is set
    /// @param mintToken address of mint token
    event MintTokenSet(address mintToken);

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param minter address of account attempting the mint
    /// @param collection address of collection that attempted mint is for
    /// @param attempts number of mint attempts
    /// @param totalMintAmount amount of $MINT tokens minted
    /// @param totalNumberOfWins total number of wins (successful mint attempts)
    /// @param totalPrizeValueAmount total ETH value of prizes won, denominated in wei
    event MintResult(
        address indexed minter,
        address indexed collection,
        uint256 attempts,
        uint256 totalMintAmount,
        uint256 totalNumberOfWins,
        uint256 totalPrizeValueAmount
    );

    /// @notice emitted when the outcome of an attempted mint is resolved on Blast
    /// @param minter address of account attempting the mint
    /// @param collection address of collection that attempted mint is for
    /// @param attempts number of mint attempts
    /// @param totalBlastYieldAmount amount of Blast yield received, denominatined in wei
    /// @param totalMintAmount amount of $MINT tokens minted
    /// @param totalNumberOfWins total number of wins (successful mint attempts)
    /// @param totalPrizeValueAmount total ETH value of prizes won, denominated in wei
    event MintResultBlast(
        address indexed minter,
        address indexed collection,
        uint256 attempts,
        uint256 totalBlastYieldAmount,
        uint256 totalMintAmount,
        uint256 totalNumberOfWins,
        uint256 totalPrizeValueAmount
    );

    /// @notice emitted when the mint token tiers are set
    /// @param mintTokenTiersData new tiers
    event MintTokenTiersSet(MintTokenTiersData mintTokenTiersData);

    /// @notice emitted when a prize is claimed
    /// @param claimer address of claimer
    /// @param prizeRecipient address of specified prize recipient
    /// @param collection address of collection prize
    event PrizeClaimed(
        address claimer,
        address prizeRecipient,
        address indexed collection
    );

    /// @notice emitted when redeemPaused is set
    /// @param status boolean value indicating whether redeeming is paused
    event RedeemPausedSet(bool status);

    /// @notice emitted when the redemption fee is set
    /// @param redemptionFeeBP redemption fee in basis points
    event RedemptionFeeSet(uint32 redemptionFeeBP);

    /// @notice emitted when the tiers are set
    /// @param tiersData new tiers
    event TiersSet(TiersData tiersData);

    /// @notice emitted when the Chainlink VRF config is set
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    event VRFConfigSet(VRFConfig config);

    /// @notice emitted when the VRF subscription LINK balance threshold is set
    /// @param vrfSubscriptionBalanceThreshold VRF subscription balance threshold
    event VRFSubscriptionBalanceThresholdSet(
        uint96 vrfSubscriptionBalanceThreshold
    );
}
