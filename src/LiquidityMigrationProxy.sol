// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "solady/auth/Ownable.sol";
import {Multicallable} from "solady/utils/Multicallable.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";

import {ICoin} from "./ICoin.sol";

/// @notice Proxy contract for managing liquidity migration and ownership operations for Coins
/// @author Coinbase
contract LiquidityMigrationProxy is Multicallable, Ownable {
    /// @notice Emitted when liquidity is migrated for a Coin to a new hook
    /// @param coin The Coin contract whose liquidity was migrated
    /// @param newHook The address of the new hook that liquidity was migrated to
    /// @param newPoolKey The new PoolKey after migration
    /// @param newPoolKeyHash The hash identifier of the new pool
    event LiquidityMigratedForCoin(ICoin indexed coin, address newHook, PoolKey newPoolKey, PoolId newPoolKeyHash);

    /// @notice Emitted when ownership is revoked for a Coin contract
    /// @param coin The Coin contract whose ownership was revoked
    event OwnershipRevokedForCoin(ICoin indexed coin);

    /// @notice Initializes the proxy with the specified owner
    /// @param owner The address that will own this proxy contract
    constructor(address owner) {
        // Solady implementation does not auto-initialize the owner
        _initializeOwner(owner);
    }

    /// @notice Migrates liquidity for a specific Coin to a new hook
    ///
    /// @param coin The Coin contract to migrate liquidity for
    /// @param newHook The address of the new hook to migrate to
    /// @param additionalData Additional data to pass to the migration function
    ///
    /// @return The new PoolKey after migration
    function migrateLiquidityForCoin(ICoin coin, address newHook, bytes calldata additionalData)
        external
        onlyOwner
        returns (PoolKey memory)
    {
        PoolKey memory newPoolKey = coin.migrateLiquidity(newHook, additionalData);
        emit LiquidityMigratedForCoin(coin, newHook, newPoolKey, PoolIdLibrary.toId(newPoolKey));
        return newPoolKey;
    }

    /// @notice Revokes ownership for a specific Coin contract
    /// @param coin The Coin contract to revoke ownership for
    function revokeOwnershipForCoin(ICoin coin) external onlyOwner {
        coin.revokeOwnership();
        emit OwnershipRevokedForCoin(coin);
    }
}
