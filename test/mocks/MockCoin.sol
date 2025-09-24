// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ICoin} from "../../src/ICoin.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";

contract MockCoin is ICoin {
    function migrateLiquidity(address newHook, bytes calldata additionalData)
        external
        returns (PoolKey memory newPoolKey)
    {}

    function revokeOwnership() external {}
}
