// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/console.sol";
import "./Settings.sol";
import "./interfaces/IExchanger.sol";

/**
 * @title Exchanger
 * @dev The Exchanger contract allows users to exchange TOKEN0 for TOKEN1 based on a predetermined exchange rate.
 * The exchange rate is determined at the time of contract deployment and remains fixed until the end of the exchange period.
 * The exchange period duration is also determined at the time of contract deployment and cannot be changed thereafter.
 * Users can preview the amount of TOKEN1 they will receive for a given amount of TOKEN0 without executing the exchange.
 * The contract owner can withdraw any remaining balance of TOKEN1 after the exchange period has ended.
 */
contract Exchanger is Ownable, IExchanger, Settings {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // The address of the TOKEN0 contract
    address public TOKEN0;

    // The address of the TOKEN1 contract
    address public TOKEN1;

    // Event that is emitted when a user exchanges TOKEN0 for TOKEN1
    event Exchanged(
        address indexed account,
        uint256 fromToken0Amount,
        uint256 toToken1Amount
    );

    /**
     * @dev Constructor function that initializes the contract.
     * @param token0 The address of the TOKEN0 contract.
     * @param token1 The address of the TOKEN1 contract.
     * @param initialExchangeRate The exchange rate of TOKEN0 to TOKEN1 at the beginning of the exchange period.
     * @param exchangePeriodDuration The duration of the exchange period in seconds.
     */
    constructor(
        address token0,
        address token1,
        uint256 initialExchangeRate,
        uint256 exchangePeriodDuration
    ) Settings(initialExchangeRate, exchangePeriodDuration) {
        TOKEN0 = token0;
        TOKEN1 = token1;
    }

    /**
     * @dev This function previews the amount of TOKEN1 to be exchanged for a given amount of TOKEN0 without executing the exchange.
     * @param token0Amount The amount of TOKEN0 to preview the exchange for.
     * @return The amount of TOKEN1 to be exchanged.
     */
    function previewExchange(
        uint256 token0Amount
    ) public view returns (uint256) {
        // Return 0 if token0Amount is zero
        if (token0Amount == 0) return 0;

        // Calculate and return the amount of TOKEN1 to be exchanged
        return calculateExchangeAmount(token0Amount);
    }

    /**
     * @dev This function exchanges the specified amount of TOKEN0 for TOKEN1.
     * @param token0Amount The amount of TOKEN0 to exchange.
     * @notice Throws an error if the token0Amount is zero, the contract has zero balance of TOKEN1,
     * or the contract does not have sufficient balance of TOKEN1 for the exchange.
     * Emits an {Exchanged} event indicating the details of the exchange.
     */
    function exchange(uint256 token0Amount) external {
        // Check if token0Amount is not zero
        if (token0Amount == 0) revert Exchanger_Token0_Amount_Cannot_Be_Zero();

        // Check if the contract has a non-zero balance of TOKEN1
        uint256 token1Balance = IERC20(TOKEN1).balanceOf(address(this));
        if (token1Balance == 0) revert Exchanger_Token1_Zero_Balance();

        // Calculate the amount of TOKEN1 to exchange
        uint256 token1Amount = calculateExchangeAmount(token0Amount);

        // Check if the contract has sufficient balance of TOKEN1 for the exchange
        if (token1Amount > token1Balance)
            revert Exchanger_Insufficient_Token1_Balance_For_Exchange();

        // Transfer token0 from the user to the owner
        IERC20(TOKEN0).safeTransferFrom(msg.sender, owner(), token0Amount);

        // Transfer token1 from the contract to the user
        IERC20(TOKEN1).safeTransfer(msg.sender, token1Amount);

        // Emit an event to indicate the details of the exchange
        emit Exchanged(msg.sender, token0Amount, token1Amount);
    }

    /**
     * @dev This function calculates the amount of TOKEN1 to be exchanged for a given amount of TOKEN0.
     * @param token0Amount The amount of TOKEN0 to exchange.
     * @return The amount of TOKEN1 to be exchanged.
     */
    function calculateExchangeAmount(
        uint256 token0Amount
    ) internal view returns (uint256) {
        // Get the decimals of TOKEN0 and TOKEN1
        uint256 token0Decimals = ERC20(TOKEN0).decimals();
        uint256 token1Decimals = ERC20(TOKEN1).decimals();

        // Calculate and return the amount of TOKEN1 to be exchanged
        return
            token0Amount
                .mul(EXCHANGE_RATE)
                .mul(10 ** token1Decimals)
                .div(10 ** (token0Decimals + token1Decimals))
                .div(10 ** (token1Decimals - token0Decimals));
    }
}
