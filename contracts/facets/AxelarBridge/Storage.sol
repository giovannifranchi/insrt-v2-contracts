// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

library AxelarBridgeStorage {
    struct Layout {
        /// @notice it stores the supported chains, the key is the destination chain and the value is the destination address
        /// @dev it uses strings to store addresses in order to support EVM and non-EVM chain address types, it is an Axelar standard
        mapping(string => string) supportedChains;
    }

    bytes32 internal constant STORAGE_SLOT = (
        keccak256("insrt.contracts.storage.AxelarBridge")
    );

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
