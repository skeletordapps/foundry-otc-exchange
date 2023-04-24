// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Settings.t.sol";

contract UpdateExchangePeriodDurationTest is SettingsTest {
    function test_davidCannotUpdateExchangePeriodDurantion() public {
        vm.startPrank(david);
        vm.expectRevert("Ownable: caller is not the owner");
        settings.updateExchangeDurationPeriod(4 days);
        vm.stopPrank();
    }

    modifier whenIsOwner() {
        _;
    }

    function test_revertWhenDurantionIsZero() public whenIsOwner {
        vm.expectRevert(Exchanger_Period_Durantion_Cannot_Be_Zero.selector);
        settings.updateExchangeDurationPeriod(0 days);
    }

    modifier whenPeriodIsNotZero() {
        _;
    }

    function test_canUpdateExchangePeriodDurantion()
        public
        whenIsOwner
        whenPeriodIsNotZero
    {
        settings.updateExchangeDurationPeriod(4 days);
        assertEq(settings.EXCHANGE_DURATION(), 4 days);
    }
}
