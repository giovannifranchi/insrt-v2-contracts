// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";

import { ITokenInternal } from "./ITokenInternal.sol";
import { TokenStorage as Storage } from "./Storage.sol";
import { AccrualData } from "./types/DataTypes.sol";
import { GuardsInternal } from "../../common/GuardsInternal.sol";

/// @title TokenInternal
/// @dev The internal functionality of the $MINT token contract.
abstract contract TokenInternal is
    ERC20BaseInternal,
    GuardsInternal,
    ITokenInternal,
    OwnableInternal
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // used for floating point calculations
    uint256 private constant SCALE = 10 ** 36;
    // used for fee calculations - not sufficient for floating point calculations
    uint32 private constant BASIS = 1000000000;

    /// @notice modifier to only allow addresses contained in mintingContracts
    /// to call modified function
    modifier onlyMintingContract() {
        if (!Storage.layout().mintingContracts.contains(msg.sender))
            revert NotMintingContract();
        _;
    }

    /// @notice returns AccrualData struct pertaining to account, which contains Token accrual
    /// information
    /// @param account address of account
    /// @return data AccrualData of account
    function _accrualData(
        address account
    ) internal view returns (AccrualData memory data) {
        data = Storage.layout().accrualData[account];
    }

    /// @notice accrues the tokens available for claiming for an account
    /// @param l TokenStorage Layout struct
    /// @param account address of account
    /// @return accountData accrualData of given account
    function _accrueTokens(
        Storage.Layout storage l,
        address account
    ) internal returns (AccrualData storage accountData) {
        accountData = l.accrualData[account];

        // calculate claimable tokens
        uint256 accruedTokens = _scaleDown(
            (l.globalRatio - accountData.offset) * _balanceOf(account)
        );

        // update account's last ratio
        accountData.offset = l.globalRatio;

        // update claimable tokens
        accountData.accruedTokens += accruedTokens;
    }

    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function _addMintingContract(address account) internal {
        Storage.layout().mintingContracts.add(account);
        emit MintingContractAdded(account);
    }

    /// @notice returns value of airdropSupply
    /// @return supply value of airdropSupply
    function _airdropSupply() internal view returns (uint256 supply) {
        supply = Storage.layout().airdropSupply;
    }

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function _BASIS() internal pure returns (uint32 value) {
        value = BASIS;
    }

    /// @notice overrides _beforeTokenTransfer hook to enforce non-transferability
    /// @param from sender of tokens
    /// @param to receiver of tokens
    /// @param amount quantity of tokens transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0) && from != address(this)) {
            if (to != address(0)) {
                revert NonTransferable();
            }
        }
    }

    /// @notice burns an amount of tokens of an account
    /// @dev parameter ordering is reversed to remove clash with ERC20BaseInternal burn(address,uint256)
    /// @param amount amount of tokens to burn
    /// @param account account to burn from
    function _burn(uint256 amount, address account) internal {
        Storage.Layout storage l = Storage.layout();

        _accrueTokens(l, account);
        _burn(account, amount);
    }

    /// @notice claims all claimable tokens for an account
    /// @param account address of account
    function _claim(address account) internal {
        Storage.Layout storage l = Storage.layout();

        // accrue tokens prior to claim
        AccrualData storage accountData = _accrueTokens(l, account);

        uint256 accruedTokens = accountData.accruedTokens;

        // decrease distribution supply by claimed tokens
        l.distributionSupply -= accruedTokens;

        // set accruedTokens of account to 0
        accountData.accruedTokens = 0;

        _transfer(address(this), account, accruedTokens);
    }

    /// @notice returns all claimable tokens of a given account
    /// @param account address of account
    /// @return amount amount of claimable tokens
    function _claimableTokens(
        address account
    ) internal view returns (uint256 amount) {
        Storage.Layout storage l = Storage.layout();
        AccrualData storage accountData = l.accrualData[account];

        amount =
            _scaleDown(
                (l.globalRatio - accountData.offset) * _balanceOf(account)
            ) +
            accountData.accruedTokens;
    }

    /// @notice Disperses tokens to a list of recipients
    /// @param recipients assumed ordered array of recipient addresses
    /// @param amounts assumed ordered array of token amounts to disperse
    function _disperseTokens(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) internal {
        Storage.Layout storage l = Storage.layout();
        uint256 totalAmount;

        for (uint256 i = 0; i < recipients.length; ++i) {
            // accrue tokens prior to disperse
            _accrueTokens(l, recipients[i]);

            require(_transfer(address(this), recipients[i], amounts[i]));

            totalAmount += amounts[i];
        }

        l.airdropSupply -= totalAmount;
    }

    /// @notice returns the distributionFractionBP value
    /// @return fractionBP value of distributionFractionBP
    function _distributionFractionBP()
        internal
        view
        returns (uint32 fractionBP)
    {
        fractionBP = Storage.layout().distributionFractionBP;
    }

    /// @notice returns the distribution supply value
    /// @return supply distribution supply value
    function _distributionSupply() internal view returns (uint256 supply) {
        supply = Storage.layout().distributionSupply;
    }

    /// @notice returns the global ratio value
    /// @return ratio global ratio value
    function _globalRatio() internal view returns (uint256 ratio) {
        ratio = Storage.layout().globalRatio;
    }

    /// @notice mint an amount of tokens to an account
    /// @dev parameter ordering is reversed to remove clash with ERC20BaseInternal mint(address,uint256)
    /// @param amount amount of tokens to disburse
    /// @param account address of account receive the tokens
    function _mint(uint256 amount, address account) internal {
        Storage.Layout storage l = Storage.layout();

        // It reverts if distributionFractionBP is not set otherwise it will fall into a modulo error
        if (l.distributionFractionBP == 0) {
            revert DistributionFractionBPNotSet();
        }

        // calculate amount for distribution
        uint256 distributionAmount = (amount * l.distributionFractionBP) /
            BASIS;

        // decrease amount to mint to account
        amount -= distributionAmount;

        uint256 accountBalance = _balanceOf(account);
        uint256 supplyDelta = _totalSupply() -
            accountBalance -
            l.distributionSupply -
            l.airdropSupply;

        AccrualData storage accountData = l.accrualData[account];

        // Always calculate and accrue previous token accruals
        uint256 previousAccruals = _scaleDown(
            (l.globalRatio - accountData.offset) * accountBalance
        );

        // Calculate the distribution ratio
        uint256 distributionRatio = _scaleUp(distributionAmount) /
            (supplyDelta > 0 ? supplyDelta : amount);

        // Update globalRatio
        l.globalRatio += distributionRatio;

        // If supplyDelta is zero, adjust the account offset differently
        if (supplyDelta == 0) {
            // Handle the case where there are no tokens in circulation
            // If this is the first minter, account offset should be one step behind globalRatio
            if (l.globalRatio % distributionRatio == 0) {
                accountData.offset = l.globalRatio - distributionRatio;
            } else {
                // Sole holder due to all other minters burning tokens
                accountData.accruedTokens +=
                    distributionAmount +
                    previousAccruals;
                accountData.offset = l.globalRatio;
            }
        } else {
            // Normal case where there are other tokens in circulation
            accountData.offset = l.globalRatio;
            accountData.accruedTokens += previousAccruals;
        }

        l.distributionSupply += distributionAmount;

        // mint tokens to contract and account
        _mint(address(this), distributionAmount);
        _mint(account, amount);
    }

    /// @notice mints an amount of tokens intended for airdrop
    /// @param amount airdrop token amount
    function _mintAirdrop(uint256 amount) internal {
        _mint(address(this), amount);

        // increase supply by the amount minted for airdrop
        Storage.layout().airdropSupply += amount;
    }

    /// @notice mints an amount of tokens as a mint referral bonus
    /// @param referrer address of mint referrer
    /// @param amount airdrop token amount
    function _mintReferral(address referrer, uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        _accrueTokens(l, referrer);
        _mint(referrer, amount);
    }

    /// @notice returns all addresses of contracts which are allowed to call mint/burn
    /// @return contracts array of addresses of contracts which are allowed to call mint/burn
    function _mintingContracts()
        internal
        view
        returns (address[] memory contracts)
    {
        contracts = Storage.layout().mintingContracts.toArray();
    }

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function _removeMintingContract(address account) internal {
        Storage.layout().mintingContracts.remove(account);
        emit MintingContractRemoved(account);
    }

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function _SCALE() internal pure returns (uint256 value) {
        value = SCALE;
    }

    /// @notice multiplies a value by the scale, to enable floating point calculations
    /// @param value value to be scaled up
    /// @return scaledValue product of value and scale
    function _scaleUp(
        uint256 value
    ) internal pure returns (uint256 scaledValue) {
        scaledValue = value * SCALE;
    }

    /// @notice divides a value by the scale, to rectify a previous scaleUp operation
    /// @param value value to be scaled down
    /// @return scaledValue value divided by scale
    function _scaleDown(
        uint256 value
    ) internal pure returns (uint256 scaledValue) {
        scaledValue = value / SCALE;
    }

    /// @notice sets a new value for distributionFractionBP
    /// @param distributionFractionBP new distributionFractionBP value
    function _setDistributionFractionBP(
        uint32 distributionFractionBP
    ) internal {
        if (distributionFractionBP == 0)
            revert DistributionFractionBPCannotBeZero();

        _enforceBasis(distributionFractionBP, BASIS);

        Storage.layout().distributionFractionBP = distributionFractionBP;
        emit DistributionFractionSet(distributionFractionBP);
    }
}
