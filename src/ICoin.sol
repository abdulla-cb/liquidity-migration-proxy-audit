// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {PoolKey} from "v4-core/types/PoolKey.sol";

interface ICoin {
    function migrateLiquidity(address newHook, bytes calldata additionalData)
        external
        returns (PoolKey memory newPoolKey);
    function revokeOwnership() external;
}
