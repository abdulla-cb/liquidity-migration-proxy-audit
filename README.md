# Liquidity Migration Proxy

The Zora Coin contract has a number of privileged functions which can only be called by the Coin's owner.

This `LiquidityMigrationProxy` can be added as an owner of the Zora coin contract at either the time of deployment, or by the coin's owner after deployment.

The owner of the `LiquidityMigrationProxy` should be able to perform a subset of the privileged operations on the Zora coin. The only privileged functions that are permitted are `migrateLiquidity` and `revokeOwnership`. 
The proxy owner should not be able to remove any of the Coin's other owners, update the Coin's metadata, or update the fee recipient for the Coin.

At any time, the Coin's other owners should be able to remove the `LiquidityMigrationProxy` as an owner.
