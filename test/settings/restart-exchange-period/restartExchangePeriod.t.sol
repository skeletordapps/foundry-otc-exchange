// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Settings.t.sol";

contract RestartExchangePeriodTest is SettingsTest {
    function test_davidCannotRestartExchangePeriod() public {
        vm.warp(block.timestamp + 4 days);
        vm.startPrank(david);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.restartExchangePeriod();
        vm.stopPrank();
    }

    modifier whenIsOwner() {
        _;
    }

    function test_canRestartExchangePeriod() public whenIsOwner {
        uint256 currentEndPeriod = settings.EXCHANGE_END_AT_UNIX_TIME();

        vm.warp(block.timestamp + 4 days);

        vm.expectEmit(true, true, true, true);
        emit ExchangeEndPeriodUpdate(
            settings.owner(),
            block.timestamp + 3 days
        );

        settings.restartExchangePeriod();
        uint256 newEndPeriod = settings.EXCHANGE_END_AT_UNIX_TIME();

        assertEq(
            settings.EXCHANGE_END_AT_UNIX_TIME(),
            block.timestamp + 3 days
        );

        assertTrue(newEndPeriod > currentEndPeriod);
    }
}
