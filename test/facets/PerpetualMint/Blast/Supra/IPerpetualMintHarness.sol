// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPerpetualMintHarnessBlast } from "../IPerpetualMintHarness.sol";
import { IPerpetualMintHarnessSupra } from "../../Supra/IPerpetualMintHarness.sol";

/// @title IPerpetualMintHarnessSupraBlast
/// @dev Extended Blast-specific, Supra-specific interface for the PerpetualMintHarness contract
interface IPerpetualMintHarnessSupraBlast is
    IPerpetualMintHarnessBlast,
    IPerpetualMintHarnessSupra
{

}
