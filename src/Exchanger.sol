// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "forge-std/console.sol";
import "./interfaces/IExchanger.sol";

contract Exchanger is Ownable, IExchanger {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public EXCHANGE_RATE;
    uint256 public EXCHANGE_DURATION = 3 days;
    uint256 public EXCHANGE_END_AT_UNIX_TIME;

    address public TOKEN0;
    address public TOKEN1;

    event ExchangeRateUpdated(
        address indexed account,
        uint256 oldExchangeRate,
        uint256 newExchangeRate
    );
    event ExchangeEndPeriodUpdate(address indexed account, uint256 timestamp);
    event Exchanged(
        address indexed account,
        uint256 fromToken0Amount,
        uint256 toToken1Amount
    );

    constructor(address token0, address token1, uint256 initialExchangeRate) {
        TOKEN0 = token0;
        TOKEN1 = token1;
        EXCHANGE_RATE = initialExchangeRate;
        EXCHANGE_END_AT_UNIX_TIME = block.timestamp + EXCHANGE_DURATION;
    }

    function updateExchangeRate(uint256 newExchangeRate) external onlyOwner {
        if (newExchangeRate == 0) revert Exchanger_Rate_Cannont_Be_Zero();

        uint256 oldExchangeRate = EXCHANGE_RATE;
        EXCHANGE_RATE = newExchangeRate;

        emit ExchangeRateUpdated(msg.sender, oldExchangeRate, newExchangeRate);
    }

    function restartExchangePeriod() external onlyOwner {
        EXCHANGE_END_AT_UNIX_TIME = block.timestamp + EXCHANGE_DURATION;

        emit ExchangeEndPeriodUpdate(msg.sender, EXCHANGE_END_AT_UNIX_TIME);
    }

    function previewExchange(
        uint256 token0Amount
    ) public view returns (uint256) {
        if (token0Amount == 0) return 0;

        return calculateExchangeAmount(token0Amount);
    }

    function exchange(uint256 token0Amount) external {
        if (token0Amount == 0) revert Exchanger_Token0_Amount_Cannot_Be_Zero();

        uint256 token1Balance = IERC20(TOKEN1).balanceOf(address(this));

        if (token1Balance == 0) revert Exchanger_Token1_Zero_Balance();

        uint256 token1Amount = calculateExchangeAmount(token0Amount);

        if (token1Amount > token1Balance)
            revert Exchanger_Insufficient_Token1_Balance_For_Exchange();

        // Transfer token0 from the user to the owner
        IERC20(TOKEN0).safeTransferFrom(msg.sender, owner(), token0Amount);

        // Transfer token1 from the contract to the user
        IERC20(TOKEN1).safeTransfer(msg.sender, token1Amount);

        emit Exchanged(msg.sender, token0Amount, token1Amount);
    }

    function calculateExchangeAmount(
        uint256 token0Amount
    ) internal view returns (uint256) {
        uint256 token0Decimals = ERC20(TOKEN0).decimals();
        uint256 token1Decimals = ERC20(TOKEN1).decimals();

        return
            token0Amount
                .mul(EXCHANGE_RATE)
                .mul(10 ** token1Decimals)
                .div(10 ** (token0Decimals + token1Decimals))
                .div(10 ** (token1Decimals - token0Decimals));
    }
}
