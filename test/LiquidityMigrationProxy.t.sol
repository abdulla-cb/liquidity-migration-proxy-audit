// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Currency} from "v4-core/types/Currency.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Test, console2} from "forge-std/Test.sol";

import {ICoin} from "../src/ICoin.sol";
import {LiquidityMigrationProxy} from "../src/LiquidityMigrationProxy.sol";
import {MockCoin} from "./mocks/MockCoin.sol";

contract LiquidityMigrationProxyTest is Test {
    LiquidityMigrationProxy public proxy;
    ICoin public coin;
    address public proxyOwner;
    address public newHook;

    PoolKey public mockPoolKey;

    error Unauthorized();

    function setUp() public {
        proxyOwner = vm.addr(1);
        newHook = vm.addr(2);
        proxy = new LiquidityMigrationProxy(proxyOwner);
        coin = new MockCoin();

        mockPoolKey = PoolKey({
            currency0: Currency.wrap(vm.addr(10)),
            currency1: Currency.wrap(vm.addr(11)),
            fee: uint24(10000),
            tickSpacing: int24(100),
            hooks: IHooks(newHook)
        });
    }

    function test_constructor_setsOwner() public view {
        assertEq(proxyOwner, proxy.owner());
    }

    function test_migrateLiquidityForCoin_performsCallOnCoin() public {
        bytes memory additionalData = "";

        vm.prank(proxyOwner);
        vm.expectEmit();
        emit LiquidityMigrationProxy.LiquidityMigratedForCoin(
            coin, newHook, mockPoolKey, PoolIdLibrary.toId(mockPoolKey)
        );
        vm.expectCall(address(coin), abi.encodeCall(ICoin.migrateLiquidity, (newHook, additionalData)));
        vm.mockCall(
            address(coin), abi.encodeCall(ICoin.migrateLiquidity, (newHook, additionalData)), abi.encode(mockPoolKey)
        );
        PoolKey memory newPoolKey = proxy.migrateLiquidityForCoin(coin, newHook, additionalData);

        assertEq(Currency.unwrap(mockPoolKey.currency0), Currency.unwrap(newPoolKey.currency0));
        assertEq(Currency.unwrap(mockPoolKey.currency1), Currency.unwrap(newPoolKey.currency1));
        assertEq(mockPoolKey.fee, newPoolKey.fee);
        assertEq(mockPoolKey.tickSpacing, newPoolKey.tickSpacing);
        assertEq(address(mockPoolKey.hooks), address(newPoolKey.hooks));
    }

    function testFuzz_migrateLiquidityForCoin_reverts_whenCalledByNonOwner(address sender) public {
        vm.assume(sender != proxyOwner);

        vm.prank(sender);
        vm.expectRevert(Unauthorized.selector);
        proxy.migrateLiquidityForCoin(coin, address(0), "");
    }

    function test_revokeOwnership_performsCallOnCoin() public {
        vm.prank(proxyOwner);
        vm.expectEmit();
        emit LiquidityMigrationProxy.OwnershipRevokedForCoin(coin);
        vm.expectCall(address(coin), abi.encodeCall(ICoin.revokeOwnership, ()));
        proxy.revokeOwnershipForCoin(coin);
    }

    function testFuzz_revokeOwnership_reverts_whenCalledByNonOwner(address sender) public {
        vm.assume(sender != proxyOwner);

        vm.prank(sender);
        vm.expectRevert(Unauthorized.selector);
        proxy.revokeOwnershipForCoin(coin);
    }

    function test_ownershipHandover() public {
        address newOwner = vm.addr(3);

        vm.prank(newOwner);
        proxy.requestOwnershipHandover();

        vm.prank(proxyOwner);
        proxy.completeOwnershipHandover(newOwner);

        assertEq(newOwner, proxy.owner());
    }

    function test_renounceProxyOwnership() public {
        vm.prank(proxyOwner);
        proxy.renounceOwnership();

        assertEq(address(0), proxy.owner());
    }

    function test_multicallMigrateLiquidityForCoin_performsCallOnCoin() public {
        bytes memory additionalData = "";
        bytes[] memory encodedCalls = new bytes[](1);

        encodedCalls[0] =
            abi.encodeCall(LiquidityMigrationProxy.migrateLiquidityForCoin, (coin, newHook, additionalData));

        vm.prank(proxyOwner);
        vm.expectEmit();
        emit LiquidityMigrationProxy.LiquidityMigratedForCoin(
            coin, newHook, mockPoolKey, PoolIdLibrary.toId(mockPoolKey)
        );
        vm.expectCall(address(coin), abi.encodeCall(ICoin.migrateLiquidity, (newHook, additionalData)));
        vm.mockCall(
            address(coin), abi.encodeCall(ICoin.migrateLiquidity, (newHook, additionalData)), abi.encode(mockPoolKey)
        );
        bytes[] memory retData = proxy.multicall(encodedCalls);

        assertEq(1, retData.length);
        PoolKey memory newPoolKey = abi.decode(retData[0], (PoolKey));

        assertEq(Currency.unwrap(mockPoolKey.currency0), Currency.unwrap(newPoolKey.currency0));
        assertEq(Currency.unwrap(mockPoolKey.currency1), Currency.unwrap(newPoolKey.currency1));
        assertEq(mockPoolKey.fee, newPoolKey.fee);
        assertEq(mockPoolKey.tickSpacing, newPoolKey.tickSpacing);
        assertEq(address(mockPoolKey.hooks), address(newPoolKey.hooks));
    }

    function testFuzz_multicallMigrateLiquidityForCoin_reverts_whenCalledByNonOwner(address sender) public {
        vm.assume(sender != proxyOwner);

        bytes memory additionalData = "";
        bytes[] memory encodedCalls = new bytes[](1);
        encodedCalls[0] =
            abi.encodeCall(LiquidityMigrationProxy.migrateLiquidityForCoin, (coin, newHook, additionalData));

        vm.prank(sender);
        vm.expectRevert(Unauthorized.selector);
        proxy.multicall(encodedCalls);
    }

    function test_multicallrevokeOwnershipForCoin_performsCallOnCoin() public {
        bytes[] memory encodedCalls = new bytes[](1);

        encodedCalls[0] = abi.encodeCall(LiquidityMigrationProxy.revokeOwnershipForCoin, (coin));

        vm.prank(proxyOwner);
        vm.expectEmit();
        emit LiquidityMigrationProxy.OwnershipRevokedForCoin(coin);
        vm.expectCall(address(coin), abi.encodeCall(ICoin.revokeOwnership, ()));
        proxy.multicall(encodedCalls);
    }

    function testFuzz_multicallRevokeOwnershipForCoin_reverts_whenCalledByNonOwner(address sender) public {
        vm.assume(sender != proxyOwner);

        bytes[] memory encodedCalls = new bytes[](1);
        encodedCalls[0] = abi.encodeCall(LiquidityMigrationProxy.revokeOwnershipForCoin, (coin));

        vm.prank(sender);
        vm.expectRevert(Unauthorized.selector);
        proxy.multicall(encodedCalls);
    }
}
