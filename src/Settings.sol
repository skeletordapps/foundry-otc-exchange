// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";
import "./interfaces/ISettings.sol";

/**
 * @title Settings Contract
 * @dev This contract is used to store and manage the settings for the project.
 */
contract Settings is Ownable, ISettings {
    uint256 public constant TOKEN0_MAX_LIMIT_PER_TX = 20_000 ether;
    uint256 public EXCHANGE_RATE;
    uint256 public EXCHANGE_DURATION;
    uint256 public EXCHANGE_END_AT_UNIX_TIME;

    /**
     * @dev Event triggered when the exchange rate is updated.
     * @param account The account that triggered the event.
     * @param oldExchangeRate The old exchange rate value.
     * @param newExchangeRate The new exchange rate value.
     */
    event ExchangeRateUpdated(
        address indexed account,
        uint256 oldExchangeRate,
        uint256 newExchangeRate
    );

    /**
     * @dev Event triggered when the exchange period end timestamp is updated.
     * @param account The account that triggered the event.
     * @param timestamp The new exchange period end timestamp.
     */
    event ExchangeEndPeriodUpdate(address indexed account, uint256 timestamp);

    /**
     * @dev Initializes the contract with initial exchange rate and exchange duration.
     * @param initialExchangeRate The initial exchange rate.
     * @param exchangePeriodDuration The duration of the exchange period in seconds.
     */
    constructor(uint256 initialExchangeRate, uint256 exchangePeriodDuration) {
        EXCHANGE_RATE = initialExchangeRate;
        EXCHANGE_DURATION = exchangePeriodDuration;
        EXCHANGE_END_AT_UNIX_TIME = block.timestamp + EXCHANGE_DURATION;
    }

    /**
     * @dev Updates the exchange rate value.
     * @param newExchangeRate The new exchange rate value.
     */
    function updateExchangeRate(uint256 newExchangeRate) external onlyOwner {
        if (newExchangeRate == 0) revert Exchanger_Rate_Cannont_Be_Zero();

        uint256 oldExchangeRate = EXCHANGE_RATE;
        EXCHANGE_RATE = newExchangeRate;

        emit ExchangeRateUpdated(msg.sender, oldExchangeRate, newExchangeRate);
    }

    /**
     * @dev Updates the exchange period duration.
     * @param exchangeDuration The new exchange period duration in seconds.
     */
    function updateExchangeDurationPeriod(
        uint256 exchangeDuration
    ) external onlyOwner {
        console.log("exchangeDuration", exchangeDuration);
        if (exchangeDuration == 0)
            revert Exchanger_Period_Durantion_Cannot_Be_Zero();

        EXCHANGE_DURATION = exchangeDuration;
    }

    /**
     * @dev Restarts the exchange period by updating the exchange end timestamp.
     */
    function restartExchangePeriod() external onlyOwner {
        EXCHANGE_END_AT_UNIX_TIME = block.timestamp + EXCHANGE_DURATION;

        emit ExchangeEndPeriodUpdate(msg.sender, EXCHANGE_END_AT_UNIX_TIME);
    }
}
