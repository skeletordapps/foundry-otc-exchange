// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../Settings.t.sol";

contract UpdateExchangeRateTest is SettingsTest {
    function test_bobCannotUpdateExchangeRate() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(bob);
        settings.updateExchangeRate(3 ether);
        vm.stopPrank();
    }

    modifier whenIsOwner() {
        _;
    }

    function test_exchangeRateCannotBeZero() public whenIsOwner {
        vm.expectRevert(Exchanger_Rate_Cannont_Be_Zero.selector);
        settings.updateExchangeRate(0 ether);
    }

    modifier whenNotZero() {
        _;
    }

    function test_canUpdateExchangeRate() public whenIsOwner whenNotZero {
        uint256 currentRate = settings.EXCHANGE_RATE();

        vm.expectEmit(true, true, true, true);
        emit ExchangeRateUpdated(settings.owner(), currentRate, 3 ether);

        settings.updateExchangeRate(3 ether);
        uint256 newRate = settings.EXCHANGE_RATE();

        assertEq(newRate, 3 ether);
    }
}
