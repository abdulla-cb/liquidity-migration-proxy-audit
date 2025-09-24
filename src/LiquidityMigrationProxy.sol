// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "solady/auth/Ownable.sol";
import {Multicallable} from "solady/utils/Multicallable.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";

import {ICoin} from "./ICoin.sol";

/// @notice Proxy contract for managing liquidity migration and ownership operations for Coins
/// @author Coinbase
contract LiquidityMigrationProxy is Multicallable, Ownable {
    /// @notice Initializes the proxy with the specified owner
    /// @param owner The address that will own this proxy contract
    constructor(address owner) {
        // Solady implementation does not auto-initialize the owner
        _initializeOwner(owner);
    }

    /// @notice Migrates liquidity for a specific Coin to a new hook
    ///
    /// @param creatorCoin The Coin contract to migrate liquidity for
    /// @param newHook The address of the new hook to migrate to
    /// @param additionalData Additional data to pass to the migration function
    ///
    /// @return The new PoolKey after migration
    function migrateLiquidityForCoin(ICoin creatorCoin, address newHook, bytes calldata additionalData)
        external
        onlyOwner
        returns (PoolKey memory)
    {
        return creatorCoin.migrateLiquidity(newHook, additionalData);
    }

    /// @notice Revokes ownership for a specific Coin contract
    /// @param creatorCoin The Coin contract to revoke ownership for
    function revokeOwnershipForCoin(ICoin creatorCoin) external onlyOwner {
        creatorCoin.revokeOwnership();
    }
}
