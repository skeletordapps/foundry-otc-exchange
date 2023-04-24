// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/interfaces/ISettings.sol";
import "../../src/Settings.sol";

contract SettingsTest is Test, ISettings {
    uint256 public initialExchangeRate;
    uint256 public exchangePeriodDuration;

    Settings public settings;

    address internal TOKEN0_ADDRESS;
    address internal TOKEN1_ADDRESS;

    address internal bob;
    address internal david;

    event ExchangeRateUpdated(
        address indexed account,
        uint256 oldExchangeRate,
        uint256 newExchangeRate
    );
    event ExchangeEndPeriodUpdate(address indexed account, uint256 timestamp);

    function setUp() public {
        initialExchangeRate = 2 ether;
        exchangePeriodDuration = 3 days;

        settings = new Settings(initialExchangeRate, exchangePeriodDuration);

        bob = vm.addr(3);
        vm.label(bob, "bob");

        david = vm.addr(4);
        vm.label(david, "david");
    }

    function test_successfully_constructed() public {
        assertEq(settings.EXCHANGE_RATE(), initialExchangeRate);
        assertEq(
            settings.EXCHANGE_END_AT_UNIX_TIME(),
            block.timestamp + exchangePeriodDuration
        );
    }
}
